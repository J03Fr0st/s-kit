$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$agentsRoot = Join-Path $root 'agents'
$readmePath = Join-Path $root 'README.md'
$cursorManifestPath = Join-Path $root '.cursor-plugin/plugin.json'
$failures = [System.Collections.Generic.List[string]]::new()

$expectedAgents = @(
  's-kit-codebase-mapper',
  's-kit-code-reviewer',
  's-kit-code-simplifier',
  's-kit-coder',
  's-kit-fixer',
  's-kit-pattern-mapper',
  's-kit-security-auditor',
  's-kit-spec-reviewer'
)

function Add-Failure {
  param([string] $Message)
  $script:failures.Add($Message) | Out-Null
}

function Get-RelativePath {
  param([string] $Path)

  $fullPath = [System.IO.Path]::GetFullPath($Path)
  if ($fullPath.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $fullPath.Substring($root.Length + 1).Replace('\', '/')
  }

  return $Path.Replace('\', '/')
}

if (-not (Test-Path $agentsRoot)) {
  Add-Failure 'Missing agents/ directory.'
} else {
  $agentFiles = Get-ChildItem $agentsRoot -Filter '*.md' -File
  $agentNames = @($agentFiles | ForEach-Object { [System.IO.Path]::GetFileNameWithoutExtension($_.Name) })

  foreach ($expected in $expectedAgents) {
    if ($expected -notin $agentNames) {
      Add-Failure "Missing expected agent: agents/$expected.md"
    }
  }

  foreach ($agentFile in $agentFiles) {
    $content = Get-Content $agentFile.FullName -Raw
    $relative = Get-RelativePath $agentFile.FullName
    $stem = [System.IO.Path]::GetFileNameWithoutExtension($agentFile.Name)

    if ($stem -notmatch '^s-kit-[a-z0-9-]+$') {
      Add-Failure "Agent filename must use s-kit-* kebab case: $relative"
    }

    if ($content -notmatch '(?s)^---\r?\n(?<frontmatter>.*?)\r?\n---\r?\n') {
      Add-Failure "Agent is missing YAML frontmatter: $relative"
      continue
    }

    $frontmatter = $Matches.frontmatter
    $nameMatch = [regex]::Match($frontmatter, '(?m)^name:\s*(?<name>[a-z0-9-]+)\s*$')
    $descriptionMatch = [regex]::Match($frontmatter, '(?m)^description:\s*(?<description>.+)\s*$')

    if (-not $nameMatch.Success) {
      Add-Failure "Agent frontmatter is missing name: $relative"
    } elseif ($nameMatch.Groups['name'].Value -ne $stem) {
      Add-Failure "Agent name must match filename for ${relative}: $($nameMatch.Groups['name'].Value)"
    }

    if (-not $descriptionMatch.Success) {
      Add-Failure "Agent frontmatter is missing description: $relative"
    } elseif ($descriptionMatch.Groups['description'].Value.Length -gt 220) {
      Add-Failure "Agent description is too long: $relative"
    }

    foreach ($heading in @('# ', '## Inputs', '## Output', '## Rules')) {
      if (-not $content.Contains($heading)) {
        Add-Failure "Agent is missing required section marker '$heading': $relative"
      }
    }

    if ($content -match '\bgsd-|/gsd|get-shit-done|open-gsd') {
      Add-Failure "Agent contains upstream GSD naming instead of s-kit naming: $relative"
    }
  }
}

if (Test-Path $readmePath) {
  $readme = Get-Content $readmePath -Raw
  foreach ($expected in $expectedAgents) {
    if (-not $readme.Contains("agents/$expected.md")) {
      Add-Failure "README must link expected agent: agents/$expected.md"
    }
  }
} else {
  Add-Failure 'Missing README.md.'
}

if (Test-Path $cursorManifestPath) {
  try {
    $cursorManifest = Get-Content $cursorManifestPath -Raw | ConvertFrom-Json
    if ([string] $cursorManifest.agents -ne './agents/') {
      Add-Failure '.cursor-plugin/plugin.json must expose agents as ./agents/.'
    }
  } catch {
    Add-Failure ".cursor-plugin/plugin.json is not valid JSON: $($_.Exception.Message)"
  }
} else {
  Add-Failure 'Missing .cursor-plugin/plugin.json.'
}

if ($failures.Count -gt 0) {
  Write-Error "Agent verification failed:`n$($failures -join "`n")"
}

Write-Host 'Agent verification passed.'
