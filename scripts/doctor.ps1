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

function Get-RepoRelativePath {
  param([string] $Path)

  $fullPath = [System.IO.Path]::GetFullPath($Path)
  if ($fullPath.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $fullPath.Substring($root.Length + 1).Replace('\', '/')
  }

  return $Path.Replace('\', '/')
}

function Test-RequiredPath {
  param(
    [string] $RelativePath,
    [ValidateSet('File', 'Directory')]
    [string] $Type = 'File'
  )

  $path = Join-RepoPath $RelativePath
  if ($Type -eq 'Directory') {
    if (-not (Test-Path $path -PathType Container)) {
      Add-Failure "Missing required directory: $RelativePath"
    }
    return
  }

  if (-not (Test-Path $path -PathType Leaf)) {
    Add-Failure "Missing required file: $RelativePath"
  }
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

function Read-JsonFile {
  param([string] $RelativePath)

  $path = Join-RepoPath $RelativePath
  try {
    return Get-Content $path -Raw | ConvertFrom-Json
  } catch {
    Add-Failure "${RelativePath} is not valid JSON: $($_.Exception.Message)"
    return $null
  }
}

function Write-Check {
  param([string] $Message)
  Write-Host "[doctor] $Message"
}

Write-Check 'Checking required repository surfaces...'

$requiredFiles = @(
  'package.json',
  '.version-bump.json',
  'README.md',
  'LICENSE',
  'NOTICE.md',
  'AGENTS.md',
  'CLAUDE.md',
  'GEMINI.md',
  'gemini-extension.json',
  '.codex-plugin/plugin.json',
  '.claude-plugin/plugin.json',
  '.claude-plugin/marketplace.json',
  '.cursor-plugin/plugin.json',
  '.opencode/plugins/s-kit.js',
  'hooks/hooks.json',
  'hooks/hooks-cursor.json',
  'assets/s-kit-small.svg',
  'assets/app-icon.png',
  'scripts/bump-version.sh'
)

foreach ($file in $requiredFiles) {
  Test-RequiredPath $file
}

foreach ($dir in @('skills', 'agents', 'tests', 'hooks', 'assets', '.github', '.codex-plugin', '.claude-plugin', '.cursor-plugin', '.opencode')) {
  Test-RequiredPath $dir 'Directory'
}

Write-Check 'Checking version consistency...'

$versionConfig = Read-JsonFile '.version-bump.json'
if ($null -ne $versionConfig) {
  $versions = @()
  foreach ($entry in @($versionConfig.files)) {
    $path = [string] $entry.path
    $field = [string] $entry.field
    Test-RequiredPath $path
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

Write-Check 'Checking plugin manifest paths...'

$codex = Read-JsonFile '.codex-plugin/plugin.json'
if ($null -ne $codex) {
  if ($codex.name -ne 's-kit') { Add-Failure '.codex-plugin/plugin.json name must be s-kit.' }
  if ($codex.skills -ne './skills/') { Add-Failure '.codex-plugin/plugin.json must expose skills as ./skills/.' }
  if ($codex.interface.composerIcon -ne './assets/s-kit-small.svg') { Add-Failure '.codex-plugin/plugin.json composerIcon must point to ./assets/s-kit-small.svg.' }
  if ($codex.interface.logo -ne './assets/app-icon.png') { Add-Failure '.codex-plugin/plugin.json logo must point to ./assets/app-icon.png.' }
}

$cursor = Read-JsonFile '.cursor-plugin/plugin.json'
if ($null -ne $cursor) {
  if ($cursor.name -ne 's-kit') { Add-Failure '.cursor-plugin/plugin.json name must be s-kit.' }
  if ($cursor.skills -ne './skills/') { Add-Failure '.cursor-plugin/plugin.json must expose skills as ./skills/.' }
  if ($cursor.agents -ne './agents/') { Add-Failure '.cursor-plugin/plugin.json must expose agents as ./agents/.' }
  if ($cursor.hooks -ne './hooks/hooks-cursor.json') { Add-Failure '.cursor-plugin/plugin.json must expose hooks as ./hooks/hooks-cursor.json.' }
}

$claude = Read-JsonFile '.claude-plugin/plugin.json'
if ($null -ne $claude -and $claude.name -ne 's-kit') {
  Add-Failure '.claude-plugin/plugin.json name must be s-kit.'
}

$marketplace = Read-JsonFile '.claude-plugin/marketplace.json'
if ($null -ne $marketplace) {
  if ($marketplace.plugins.Count -lt 1) {
    Add-Failure '.claude-plugin/marketplace.json must include at least one plugin entry.'
  } elseif ($marketplace.plugins[0].name -ne 's-kit') {
    Add-Failure '.claude-plugin/marketplace.json first plugin must be s-kit.'
  }
}

$gemini = Read-JsonFile 'gemini-extension.json'
if ($null -ne $gemini) {
  if ($gemini.name -ne 's-kit') { Add-Failure 'gemini-extension.json name must be s-kit.' }
  if ($gemini.contextFileName -ne 'GEMINI.md') { Add-Failure 'gemini-extension.json contextFileName must be GEMINI.md.' }
}

Write-Check 'Checking required skills and agents...'

$requiredSkills = @(
  'using-s-kit',
  'brainstorming',
  'plan-feature',
  'build-feature',
  'grill-me',
  'grill-with-docs',
  'systematic-debugging',
  'test-driven-development',
  'requesting-code-review',
  'verification-before-completion'
)

foreach ($skill in $requiredSkills) {
  Test-RequiredPath "skills/$skill/SKILL.md"
}

$skillCount = 0
if (Test-Path (Join-RepoPath 'skills') -PathType Container) {
  $skillCount = @(Get-ChildItem (Join-RepoPath 'skills') -Recurse -Filter 'SKILL.md' -File).Count
}
if ($skillCount -lt $requiredSkills.Count) {
  Add-Failure "Expected at least $($requiredSkills.Count) skills, found $skillCount."
}

$requiredAgents = @(
  's-kit-codebase-mapper',
  's-kit-code-reviewer',
  's-kit-code-simplifier',
  's-kit-coder',
  's-kit-fixer',
  's-kit-pattern-mapper',
  's-kit-security-auditor',
  's-kit-spec-reviewer'
)

foreach ($agent in $requiredAgents) {
  Test-RequiredPath "agents/$agent.md"
}

Write-Check 'Checking retired paths are absent...'

$oldPlanName = 'create' + '-spec'
$oldBuildName = 'implement' + '-feature'
$oldWritingPlansName = 'writing' + '-plans'
$oldExecutingPlansName = 'executing' + '-plans'
$oldSubagentDrivenName = 'subagent' + '-driven-development'

foreach ($retiredPath in @(
  "skills/$oldPlanName",
  "skills/$oldBuildName",
  "skills/$oldWritingPlansName",
  "skills/$oldExecutingPlansName",
  "skills/$oldSubagentDrivenName"
)) {
  if (Test-Path (Join-RepoPath $retiredPath)) {
    Add-Failure "Retired path must not exist: $retiredPath"
  }
}

Write-Check 'Checking JavaScript plugin syntax...'

$pluginPath = Join-RepoPath '.opencode/plugins/s-kit.js'
if (Test-Path $pluginPath -PathType Leaf) {
  & node --check $pluginPath | Out-Null
  if ($LASTEXITCODE -ne 0) {
    Add-Failure '.opencode/plugins/s-kit.js failed node --check.'
  }
}

Write-Check 'Checking packaging hygiene...'

$excludedDirectories = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($name in @('.git', 'node_modules', '.serena', '.worktrees')) {
  $excludedDirectories.Add($name) | Out-Null
}

$suspiciousFiles = [System.Collections.Generic.List[string]]::new()
Get-ChildItem $root -Recurse -File -Force | ForEach-Object {
  $relative = Get-RepoRelativePath $_.FullName
  $parts = $relative.Split('/')
  foreach ($part in $parts) {
    if ($excludedDirectories.Contains($part)) {
      return
    }
  }

  if ($_.Name -match '(^\.env$|\.pem$|\.pfx$|\.key$|^id_rsa$|^id_ed25519$|credentials\.json$|\.map$)') {
    $suspiciousFiles.Add($relative) | Out-Null
  }
}

if ($suspiciousFiles.Count -gt 0) {
  Add-Failure "Suspicious packaging files found:`n$($suspiciousFiles -join "`n")"
}

if ($failures.Count -gt 0) {
  Write-Error "s-kit doctor failed:`n$($failures -join "`n")"
}

Write-Host 's-kit doctor passed.'
