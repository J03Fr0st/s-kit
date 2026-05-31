$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$failures = [System.Collections.Generic.List[string]]::new()
$oldPlanName = 'create' + '-spec'
$oldBuildName = 'implement' + '-feature'
$retiredNameTerm = 'retired ' + 'name'
$oldAliasTerm = 'Legacy ' + 'alias'
$oldAliasTermLower = 'legacy ' + 'alias'

function Add-Failure {
  param([string] $Message)
  $script:failures.Add($Message) | Out-Null
}

function Join-RepoPath {
  param([string] $RelativePath)
  return Join-Path $root ($RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
}

function Require-File {
  param([string] $RelativePath)
  if (-not (Test-Path (Join-RepoPath $RelativePath))) {
    Add-Failure "Missing required file: $RelativePath"
  }
}

function Require-MissingPath {
  param([string] $RelativePath)
  if (Test-Path (Join-RepoPath $RelativePath)) {
    Add-Failure "Legacy skill path must not exist: $RelativePath"
  }
}

function Require-Contains {
  param(
    [string] $RelativePath,
    [string] $Text
  )

  $path = Join-RepoPath $RelativePath
  if (-not (Test-Path $path)) {
    Add-Failure "Cannot inspect missing file: $RelativePath"
    return
  }

  $content = Get-Content $path -Raw
  if (-not $content.Contains($Text)) {
    Add-Failure "${RelativePath} must contain: $Text"
  }
}

function Require-NotContains {
  param(
    [string] $RelativePath,
    [string] $Text
  )

  $path = Join-RepoPath $RelativePath
  if (-not (Test-Path $path)) {
    Add-Failure "Cannot inspect missing file: $RelativePath"
    return
  }

  $content = Get-Content $path -Raw
  if ($content.Contains($Text)) {
    Add-Failure "${RelativePath} must not contain legacy name: $Text"
  }
}

$requiredFiles = @(
  'skills/plan-feature/SKILL.md',
  'skills/plan-feature/references/readme-template.md',
  'skills/plan-feature/references/requirements-template.md',
  'skills/plan-feature/references/action-required-template.md',
  'skills/plan-feature/references/task-template.md',
  'skills/plan-feature/references/spec-json-template.json',
  'skills/build-feature/SKILL.md',
  'skills/build-feature/references/coder-prompt-template.md',
  'skills/build-feature/references/review-prompt-template.md',
  'skills/build-feature/references/fix-prompt-template.md'
)

foreach ($file in $requiredFiles) {
  Require-File $file
}

Require-Contains 'skills/plan-feature/SKILL.md' 'name: plan-feature'
Require-Contains 'skills/build-feature/SKILL.md' 'name: build-feature'
Require-MissingPath "skills/$oldPlanName"
Require-MissingPath "skills/$oldBuildName"

$canonicalFiles = @(
  'README.md',
  'skills/using-s-kit/SKILL.md',
  'skills/brainstorming/SKILL.md',
  'skills/writing-plans/SKILL.md',
  'skills/executing-plans/SKILL.md',
  'skills/subagent-driven-development/SKILL.md',
  'agents/s-kit-codebase-mapper.md',
  'agents/s-kit-pattern-mapper.md'
)

foreach ($file in $canonicalFiles) {
  Require-Contains $file 'plan-feature'
  Require-Contains $file 'build-feature'
  Require-NotContains $file $oldPlanName
  Require-NotContains $file $oldBuildName
}

Require-Contains 'README.md' 'brainstorming -> plan-feature -> build-feature -> verification/review -> ship'
Require-Contains 'skills/using-s-kit/SKILL.md' 'brainstorming -> plan-feature -> build-feature -> verification/review -> ship'

$legacyPattern = "$oldPlanName|$oldBuildName|$oldAliasTerm|$oldAliasTermLower|$retiredNameTerm"
$legacyMatches = & rg -n $legacyPattern -g '!scripts/verify-skill-names.ps1' $root
if ($LASTEXITCODE -eq 0) {
  Add-Failure "Legacy naming remains in active repo surface:`n$legacyMatches"
} elseif ($LASTEXITCODE -gt 1) {
  exit $LASTEXITCODE
}

if ($failures.Count -gt 0) {
  Write-Error "Skill naming verification failed:`n$($failures -join "`n")"
}

Write-Host 'Skill naming verification passed.'
