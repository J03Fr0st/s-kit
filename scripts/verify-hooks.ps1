# Verifies that the two hook registration files stay in sync and that the
# declared packaging version fields match.
#
# Allowed platform differences between hooks/hooks.json (Claude Code/Codex/
# OpenCode format) and hooks/hooks-cursor.json (Cursor format) — these are
# documented differences, not drift, and are NOT flagged:
#   - Matchers: hooks.json registers per-matcher groups (e.g. startup, resume,
#     clear, compact); Cursor has no matcher concept. Matchers are ignored.
#   - Event-name casing: hooks.json uses PascalCase (SessionStart); Cursor uses
#     camelCase (sessionStart). Event names are compared case-insensitively.
#   - Path prefix style: hooks.json commands are quoted and use
#     ${PLUGIN_ROOT}/; Cursor commands use a relative ./ prefix. Commands are
#     normalized to their hook-script identity (e.g.
#     "hooks/run-hook.cmd session-start") before comparison.
#
# The version-consistency section intentionally duplicates the check in
# scripts/doctor.ps1: doctor is on-demand, npm test is the gate. Both read
# .version-bump.json so they can never disagree about scope.

$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
  param([string] $Message)
  $script:failures.Add($Message) | Out-Null
}

function Join-RepoPath {
  param([string] $RelativePath)
  return Join-Path $root ($RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
}

function Read-JsonFile {
  param([string] $RelativePath)

  $path = Join-RepoPath $RelativePath
  if (-not (Test-Path $path -PathType Leaf)) {
    Add-Failure "Missing required file: $RelativePath"
    return $null
  }

  try {
    # Windows PowerShell 5.1: ConvertFrom-Json returns $null for empty or
    # whitespace-only input without throwing, so check the result explicitly.
    $json = Get-Content $path -Raw | ConvertFrom-Json
  } catch {
    Add-Failure "${RelativePath} is not valid JSON: $($_.Exception.Message)"
    return $null
  }

  if ($null -eq $json) {
    Add-Failure "${RelativePath} exists but is empty or not a JSON object"
    return $null
  }

  return $json
}

function Get-JsonField {
  param(
    [object] $Json,
    [string] $FieldPath
  )

  $current = $Json
  foreach ($part in $FieldPath.Split('.')) {
    if ($null -eq $current) {
      return $null
    }

    if ($part -match '^\d+$') {
      $index = [int] $part
      if ($current.Count -le $index) {
        return $null
      }
      $current = $current[$index]
      continue
    }

    $property = $current.PSObject.Properties[$part]
    if ($null -eq $property) {
      return $null
    }

    $current = $property.Value
  }

  return $current
}

function Get-NormalizedHookCommand {
  param([string] $Command)
  $value = $Command.Trim().Trim('"')
  $value = $value -replace '^\$\{PLUGIN_ROOT\}/', ''
  $value = $value -replace '^\./', ''
  $value = $value -replace '"', ''
  return $value.Trim()
}

# --- Hook invocation sync between hooks.json and hooks-cursor.json ---

$claudeHooksJson = Read-JsonFile 'hooks/hooks.json'
$cursorHooksJson = Read-JsonFile 'hooks/hooks-cursor.json'

# Map of lowercased event name -> HashSet of normalized commands, per file.
function Get-ClaudeInvocations {
  param([object] $Json)

  $invocations = @{}
  if ($null -eq $Json -or $null -eq $Json.hooks) {
    return $invocations
  }

  foreach ($eventProperty in $Json.hooks.PSObject.Properties) {
    $eventKey = $eventProperty.Name.ToLowerInvariant()
    if (-not $invocations.ContainsKey($eventKey)) {
      $invocations[$eventKey] = [System.Collections.Generic.HashSet[string]]::new()
    }
    foreach ($group in @($eventProperty.Value)) {
      foreach ($hook in @($group.hooks)) {
        if ($null -ne $hook -and -not [string]::IsNullOrWhiteSpace([string] $hook.command)) {
          $invocations[$eventKey].Add((Get-NormalizedHookCommand ([string] $hook.command))) | Out-Null
        }
      }
    }
  }

  return $invocations
}

function Get-CursorInvocations {
  param([object] $Json)

  $invocations = @{}
  if ($null -eq $Json -or $null -eq $Json.hooks) {
    return $invocations
  }

  foreach ($eventProperty in $Json.hooks.PSObject.Properties) {
    $eventKey = $eventProperty.Name.ToLowerInvariant()
    if (-not $invocations.ContainsKey($eventKey)) {
      $invocations[$eventKey] = [System.Collections.Generic.HashSet[string]]::new()
    }
    foreach ($entry in @($eventProperty.Value)) {
      if ($null -ne $entry -and -not [string]::IsNullOrWhiteSpace([string] $entry.command)) {
        $invocations[$eventKey].Add((Get-NormalizedHookCommand ([string] $entry.command))) | Out-Null
      }
    }
  }

  return $invocations
}

$claudeInvocations = Get-ClaudeInvocations $claudeHooksJson
$cursorInvocations = Get-CursorInvocations $cursorHooksJson

if ($null -ne $claudeHooksJson -and $null -ne $cursorHooksJson) {
  $allEvents = [System.Collections.Generic.HashSet[string]]::new()
  foreach ($key in $claudeInvocations.Keys) { $allEvents.Add($key) | Out-Null }
  foreach ($key in $cursorInvocations.Keys) { $allEvents.Add($key) | Out-Null }

  foreach ($eventKey in ($allEvents | Sort-Object)) {
    $claudeSet = if ($claudeInvocations.ContainsKey($eventKey)) { $claudeInvocations[$eventKey] } else { [System.Collections.Generic.HashSet[string]]::new() }
    $cursorSet = if ($cursorInvocations.ContainsKey($eventKey)) { $cursorInvocations[$eventKey] } else { [System.Collections.Generic.HashSet[string]]::new() }

    foreach ($command in ($claudeSet | Sort-Object)) {
      if (-not $cursorSet.Contains($command)) {
        Add-Failure "Hook '$command' (event '$eventKey') is registered in hooks/hooks.json but missing from hooks/hooks-cursor.json."
      }
    }
    foreach ($command in ($cursorSet | Sort-Object)) {
      if (-not $claudeSet.Contains($command)) {
        Add-Failure "Hook '$command' (event '$eventKey') is registered in hooks/hooks-cursor.json but missing from hooks/hooks.json."
      }
    }
  }
}

# --- Referenced hook script files exist on disk ---

$referencedPaths = [System.Collections.Generic.HashSet[string]]::new()
foreach ($invocationMap in @($claudeInvocations, $cursorInvocations)) {
  foreach ($set in $invocationMap.Values) {
    foreach ($command in $set) {
      $tokens = @($command -split '\s+' | Where-Object { $_.Length -gt 0 })
      if ($tokens.Count -ge 1) {
        $referencedPaths.Add($tokens[0]) | Out-Null
      }
      # run-hook.cmd dispatches to a script in hooks/ named by its argument.
      if ($tokens.Count -ge 2 -and $tokens[0] -match 'run-hook\.cmd$') {
        $referencedPaths.Add("hooks/$($tokens[1])") | Out-Null
      }
    }
  }
}

foreach ($relativePath in ($referencedPaths | Sort-Object)) {
  if (-not (Test-Path (Join-RepoPath $relativePath) -PathType Leaf)) {
    Add-Failure "Referenced hook script does not exist: $relativePath"
  }
}

# --- Version consistency across .version-bump.json-declared files ---

$versionConfig = Read-JsonFile '.version-bump.json'
if ($null -ne $versionConfig) {
  $versions = @()
  foreach ($entry in @($versionConfig.files)) {
    $path = [string] $entry.path
    $field = [string] $entry.field
    $json = Read-JsonFile $path
    if ($null -eq $json) {
      continue
    }

    $value = Get-JsonField $json $field
    if ([string]::IsNullOrWhiteSpace([string] $value)) {
      Add-Failure "${path} does not contain version field: $field"
      continue
    }

    $versions += [string] $value
  }

  $uniqueVersions = @($versions | Sort-Object -Unique)
  if ($uniqueVersions.Count -gt 1) {
    Add-Failure "Version drift detected across declared files: $($uniqueVersions -join ', ')"
  }
}

if ($failures.Count -gt 0) {
  foreach ($failure in $failures) {
    Write-Host "verify-hooks: FAIL - $failure"
  }
  exit 1
}

Write-Host 'verify-hooks: OK'
exit 0
