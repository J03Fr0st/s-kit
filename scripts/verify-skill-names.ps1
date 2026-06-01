$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$failures = [System.Collections.Generic.List[string]]::new()
$oldPlanName = 'create' + '-spec'
$oldBuildName = 'implement' + '-feature'
$retiredNameTerm = 'retired ' + 'name'
$oldAliasTerm = 'Legacy ' + 'alias'
$oldAliasTermLower = 'legacy ' + 'alias'
$oldWritingPlansName = 'writing' + '-plans'
$oldExecutingPlansName = 'executing' + '-plans'
$oldSubagentDrivenName = 'subagent' + '-driven-development'

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
  'skills/grill-me/SKILL.md',
  'skills/grill-with-docs/SKILL.md',
  'skills/grill-with-docs/CONTEXT-FORMAT.md',
  'skills/grill-with-docs/ADR-FORMAT.md',
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
Require-Contains 'skills/grill-me/SKILL.md' 'name: grill-me'
Require-Contains 'skills/grill-with-docs/SKILL.md' 'name: grill-with-docs'
Require-MissingPath "skills/$oldPlanName"
Require-MissingPath "skills/$oldBuildName"
Require-MissingPath "skills/$oldWritingPlansName"
Require-MissingPath "skills/$oldExecutingPlansName"
Require-MissingPath "skills/$oldSubagentDrivenName"

$canonicalFiles = @(
  'README.md',
  'skills/using-s-kit/SKILL.md',
  'skills/brainstorming/SKILL.md',
  'agents/s-kit-codebase-mapper.md',
  'agents/s-kit-pattern-mapper.md'
)

foreach ($file in $canonicalFiles) {
  Require-Contains $file 'plan-feature'
  Require-Contains $file 'build-feature'
  Require-NotContains $file $oldPlanName
  Require-NotContains $file $oldBuildName
  Require-NotContains $file $oldWritingPlansName
  Require-NotContains $file $oldExecutingPlansName
  Require-NotContains $file $oldSubagentDrivenName
}

Require-Contains 'README.md' 'brainstorming -> plan-feature -> build-feature -> verification/review -> ship'
Require-Contains 'skills/using-s-kit/SKILL.md' 'brainstorming -> plan-feature -> build-feature -> verification/review -> ship'
Require-Contains 'README.md' 'grill-with-docs'
Require-Contains 'README.md' 'grill-me'
Require-Contains '.codex-plugin/plugin.json' 'grill-me'
Require-Contains 'skills/grill-me/SKILL.md' 'Ask the questions one at a time.'
Require-Contains 'skills/using-s-kit/SKILL.md' 'grill-with-docs'
Require-Contains 'skills/brainstorming/SKILL.md' 'Write `design.md` as the review artifact before final approval, then stop.'
Require-Contains 'skills/plan-feature/SKILL.md' 'Do not treat a drafted `design.md` as approved until the user approves it after reviewing the file.'
Require-Contains 'skills/brainstorming/SKILL.md' 'Offer `grill-me` as an optional review step after writing the design file.'
Require-Contains 'skills/plan-feature/SKILL.md' 'Record design approval before spec creation in `implementation-log.md`.'
Require-Contains 'skills/plan-feature/SKILL.md' 'Do not write a "Spec Created" entry before approval evidence.'
Require-Contains 'skills/brainstorming/references/design-template.md' '## Configuration and Inputs'
Require-Contains 'skills/brainstorming/references/design-template.md' 'Distinguish stored configuration, command arguments, defaults, and per-command overrides.'

$legacyPattern = "$oldPlanName|$oldBuildName|$oldWritingPlansName|$oldExecutingPlansName|$oldSubagentDrivenName|$oldAliasTerm|$oldAliasTermLower|$retiredNameTerm|Workflow redirects|Workflow Redirect"
# The docs/*-research/comparison notes legitimately reference the retired names
# (e.g. "verify create-spec is absent"). They are exempt; the scan still covers
# every shipped product surface.
$legacyMatches = & rg -n $legacyPattern -g '!scripts/verify-skill-names.ps1' -g '!docs/future-development-research.md' -g '!docs/comparable-project-enhancements.md' $root
if ($LASTEXITCODE -eq 0) {
  Add-Failure "Legacy naming remains in active repo surface:`n$legacyMatches"
} elseif ($LASTEXITCODE -gt 1) {
  exit $LASTEXITCODE
}

if ($failures.Count -gt 0) {
  Write-Error "Skill naming verification failed:`n$($failures -join "`n")"
}

Write-Host 'Skill naming verification passed.'
