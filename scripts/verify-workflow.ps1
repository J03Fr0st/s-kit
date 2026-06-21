$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$specRoot = Join-Path $root 'docs/specs'
$designRoot = Join-Path $root 'docs/design'
$buildFeatureSkillPath = Join-Path $root 'skills/build-feature/SKILL.md'
$reviewPromptTemplatePath = Join-Path $root 'skills/build-feature/references/review-prompt-template.md'
$simplifierPromptTemplatePath = Join-Path $root 'skills/build-feature/references/simplifier-prompt-template.md'
$coderPromptTemplatePath = Join-Path $root 'skills/build-feature/references/coder-prompt-template.md'
$fixPromptTemplatePath = Join-Path $root 'skills/build-feature/references/fix-prompt-template.md'
$usingSKitSkillPath = Join-Path $root 'skills/using-s-kit/SKILL.md'
$systematicDebuggingSkillPath = Join-Path $root 'skills/systematic-debugging/SKILL.md'
$planFeatureSkillPath = Join-Path $root 'skills/plan-feature/SKILL.md'
$requirementsTemplatePath = Join-Path $root 'skills/plan-feature/references/requirements-template.md'
$taskTemplatePath = Join-Path $root 'skills/plan-feature/references/task-template.md'
$rootContextPath = Join-Path $root 'CONTEXT.md'
$specReviewerAgentPath = Join-Path $root 'agents/s-kit-spec-reviewer.md'
$codeReviewerAgentPath = Join-Path $root 'agents/s-kit-code-reviewer.md'
$readOnlyContractPath = Join-Path $root 'skills/build-feature/references/read-only-review-contract.md'
$failures = [System.Collections.Generic.List[string]]::new()
$readOnlyReviewContractText = @(
  '# Read-Only Review Contract',
  'Do not modify files, the index, HEAD, branch state, staged changes, task statuses, or generated artifacts.',
  'read-only git commands or a separate temporary worktree',
  'Your output must state the git range, task diff, or file set reviewed.'
)
$allowedStatuses = @(
  'pending',
  'in-progress',
  'blocked',
  'needs-context',
  'done-with-concerns',
  'review-failed',
  'complete'
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

function Join-RepoPath {
  param([string] $RelativePath)
  return Join-Path $root ($RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
}

function Get-FirstSectionValue {
  param(
    [string] $Content,
    [string] $Heading
  )

  $lines = $Content -split "`r?`n"
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim() -eq "## $Heading") {
      for ($j = $i + 1; $j -lt $lines.Count; $j++) {
        $value = $lines[$j].Trim()
        if ($value.Length -gt 0) {
          return $value
        }
      }
    }
  }

  return $null
}

function Test-Heading {
  param(
    [string] $Content,
    [string] $Heading
  )

  $escaped = [regex]::Escape($Heading)
  return $Content -match "(?m)^$escaped\s*$"
}

function Test-ExactArray {
  param(
    [object[]] $Actual,
    [string[]] $Expected
  )

  if ($Actual.Count -ne $Expected.Count) {
    return $false
  }

  for ($i = 0; $i -lt $Expected.Count; $i++) {
    if ([string] $Actual[$i] -ne $Expected[$i]) {
      return $false
    }
  }

  return $true
}

function Get-TaskFileNameFromManifestPath {
  param([string] $ManifestFile)
  return [System.IO.Path]::GetFileName($ManifestFile.Replace('\', '/'))
}

function Get-TaskOwnedFiles {
  param([object] $Task)

  $owned = [System.Collections.Generic.List[string]]::new()
  if ($null -ne $Task.files) {
    foreach ($file in @($Task.files.create) + @($Task.files.modify)) {
      $value = ([string] $file).Trim()
      if ($value -and $value -notin @('None', 'N/A', '-')) {
        $owned.Add($value.ToLowerInvariant()) | Out-Null
      }
    }
  }

  return $owned
}

if (Test-Path $specRoot) {
  Get-ChildItem $specRoot -Recurse -Filter 'design.md' -File | ForEach-Object {
    Add-Failure "Spec-local design file is not allowed: $(Get-RelativePath $_.FullName)"
  }
}

if (Test-Path $designRoot) {
  Get-ChildItem $designRoot -Filter 'design.md' -File | ForEach-Object {
    Add-Failure "Loose design file is not allowed directly under docs/design: $(Get-RelativePath $_.FullName)"
  }
}

if (Test-Path $buildFeatureSkillPath) {
  $buildFeatureSkill = Get-Content $buildFeatureSkillPath -Raw
  foreach ($requiredText in @(
    '### Step 5A: Simplification Pass',
    'references/simplifier-prompt-template.md',
    's-kit-code-simplifier',
    'After coder or fix agents complete',
    'If Step 5A fails or either review returns **FAIL**',
    'Check maintainability, simplicity, security',
    'The simplification pass stayed within the changed-file scope and did not alter approved behavior',
    'coder or fixer completion summary, simplifier summary, and simplifier verification evidence',
    '### Step 3A: Phase Risk Preflight',
    '{phase_risk_preflight}',
    '{design_digest}',
    'baseline verification',
    's-kit-security-auditor',
    'Reopened completed task',
    'A `no-op` result must include Final Verification command output',
    'complete punch-list review',
    'repeated same-boundary failure',
    'Boundary Context',
    'build a concrete review scope',
    'git range, task diff, or file set',
    'Requirements and task files must preserve relevant glossary terms and ADR constraints when context docs exist.',
    'Glossary terms, avoided synonyms, and ADR constraints from the approved spec context are preserved.',
    'Check that naming and abstractions do not drift away from `CONTEXT.md` glossary terms or contradict accepted ADRs.',
    'Do not ask them to modify files, the index, HEAD, branch state, staged changes, task statuses, or generated artifacts',
    'read-only git commands or a separate temporary worktree'
  )) {
    if (-not $buildFeatureSkill.Contains($requiredText)) {
      Add-Failure "build-feature workflow must include required orchestration text: $requiredText"
    }
  }
} else {
  Add-Failure 'Missing build-feature skill: skills/build-feature/SKILL.md'
}

if (Test-Path $readOnlyContractPath) {
  $readOnlyContract = Get-Content $readOnlyContractPath -Raw
  foreach ($requiredText in $readOnlyReviewContractText) {
    if (-not $readOnlyContract.Contains($requiredText)) {
      Add-Failure "read-only review contract must include contract text: $requiredText"
    }
  }
} else {
  Add-Failure 'Missing read-only review contract: skills/build-feature/references/read-only-review-contract.md'
}

if (Test-Path $reviewPromptTemplatePath) {
  $reviewPromptTemplate = Get-Content $reviewPromptTemplatePath -Raw
  foreach ($requiredText in @(
    'Verify the simplification pass stayed within the changed-file scope and did not alter approved behavior.',
    'Check maintainability, simplicity, security, performance, error handling, and project conventions.',
    'simplifier summary and verification evidence',
    'Acceptance Criteria and Verification Plan sections',
    '## Phase Risk Preflight',
    '{phase_risk_preflight}',
    'complete punch-list mode',
    '{review_scope}',
    '{read_only_contract}',
    'read-only-review-contract.md',
    'Verify glossary terms, avoided synonyms, and ADR constraints from the approved spec context are preserved.',
    'Check naming and abstractions against `CONTEXT.md` glossary terms and accepted ADRs when those docs exist.'
  )) {
    if (-not $reviewPromptTemplate.Contains($requiredText)) {
      Add-Failure "review prompt must include simplifier review text: $requiredText"
    }
  }
} else {
  Add-Failure 'Missing build-feature review prompt template: skills/build-feature/references/review-prompt-template.md'
}

if (Test-Path $coderPromptTemplatePath) {
  $coderPromptTemplate = Get-Content $coderPromptTemplatePath -Raw
  foreach ($requiredText in @(
    '## Design Digest',
    '{design_digest}',
    'Account for the contracts, glossary terms, ADR constraints, and conventions in the Design Digest',
    'glossary terms, ADR constraints'
  )) {
    if (-not $coderPromptTemplate.Contains($requiredText)) {
      Add-Failure "coder prompt must include design digest text: $requiredText"
    }
  }
  foreach ($forbiddenText in @('{phase_risk_preflight}', '{requirements}')) {
    if ($coderPromptTemplate.Contains($forbiddenText)) {
      Add-Failure "coder prompt must not include full-context placeholder: $forbiddenText"
    }
  }
  if ($coderPromptTemplate -match '\{design\}') {
    Add-Failure 'coder prompt must not include full-context placeholder: {design}'
  }
} else {
  Add-Failure 'Missing build-feature coder prompt template: skills/build-feature/references/coder-prompt-template.md'
}

if (Test-Path $simplifierPromptTemplatePath) {
  $simplifierPromptTemplate = Get-Content $simplifierPromptTemplatePath -Raw
  foreach ($requiredText in @(
    'After a trivial targeted fix, you may return `no-op`',
    'you must still run each task''s Final Verification command',
    'Preserve contracts, glossary terms, and ADR constraints'
  )) {
    if (-not $simplifierPromptTemplate.Contains($requiredText)) {
      Add-Failure "simplifier prompt must include no-op verification text: $requiredText"
    }
  }
  if ($simplifierPromptTemplate.Contains('{phase_risk_preflight}')) {
    Add-Failure 'simplifier prompt must not include full-context placeholder: {phase_risk_preflight}'
  }
} else {
  Add-Failure 'Missing build-feature simplifier prompt template: skills/build-feature/references/simplifier-prompt-template.md'
}

if (Test-Path $fixPromptTemplatePath) {
  $fixPromptTemplate = Get-Content $fixPromptTemplatePath -Raw
  foreach ($requiredText in @(
    '## Phase Risk Preflight',
    '{phase_risk_preflight}',
    '## Boundary Context',
    '{boundary_context}',
    'complete punch-list mode',
    'glossary terms, and ADR constraints'
  )) {
    if (-not $fixPromptTemplate.Contains($requiredText)) {
      Add-Failure "fix prompt must include punch-list context text: $requiredText"
    }
  }
} else {
  Add-Failure 'Missing build-feature fix prompt template: skills/build-feature/references/fix-prompt-template.md'
}

if (Test-Path $usingSKitSkillPath) {
  $usingSKitSkill = Get-Content $usingSKitSkillPath -Raw
  foreach ($requiredText in @(
    'quick-change` -> `verification-before-completion',
    'systematic-debugging` -> `test-driven-development` -> `verification-before-completion',
    'If a quick change is actually broken behavior',
    'If a bug fix grows beyond roughly 3 files',
    '## Domain Docs Contract',
    'When a repo has `CONTEXT.md`, `CONTEXT-MAP.md`, or `docs/adr/`, treat those files as binding language and decision inputs.',
    '`CONTEXT.md` is a glossary, not a spec.'
  )) {
    if (-not $usingSKitSkill.Contains($requiredText)) {
      Add-Failure "using-s-kit routing must include quick/bug lane contract text: $requiredText"
    }
  }
} else {
  Add-Failure 'Missing using-s-kit skill: skills/using-s-kit/SKILL.md'
}

if (Test-Path $systematicDebuggingSkillPath) {
  $systematicDebuggingSkill = Get-Content $systematicDebuggingSkillPath -Raw
  foreach ($requiredText in @(
    '## s-kit Bug Lane Contract',
    'systematic-debugging -> test-driven-development -> verification-before-completion',
    '.s-kit/debug/YYYY-MM-DD-{slug}.md',
    'requesting-code-review` is required for complex bugs',
    'Read Domain Docs When Present',
    'If `CONTEXT.md` exists, use glossary terms in hypotheses, repro names, test names, and fix summaries'
  )) {
    if (-not $systematicDebuggingSkill.Contains($requiredText)) {
      Add-Failure "systematic-debugging must include bug lane contract text: $requiredText"
    }
  }
} else {
  Add-Failure 'Missing systematic-debugging skill: skills/systematic-debugging/SKILL.md'
}

if (Test-Path $planFeatureSkillPath) {
  $planFeatureSkill = Get-Content $planFeatureSkillPath -Raw
  foreach ($requiredText in @(
    'Read `CONTEXT-MAP.md`, relevant `CONTEXT.md` files, and ADRs in `docs/adr/` when present.',
    '**Domain context**: glossary terms, avoided synonyms, context boundaries, and ADR constraints relevant to the task',
    '`tasks[]` entries with `id`, `title`, `file`, `phase`, `status`, `dependsOn`, `blocks`, `files.create`, `files.modify`, and `verificationCommands`',
    'Capture glossary and ADR constraints from `CONTEXT.md`, `CONTEXT-MAP.md`, and `docs/adr/` in requirements and task files when those docs exist.'
  )) {
    if (-not $planFeatureSkill.Contains($requiredText)) {
      Add-Failure "plan-feature must include domain context planning text: $requiredText"
    }
  }
} else {
  Add-Failure 'Missing plan-feature skill: skills/plan-feature/SKILL.md'
}

if (Test-Path $requirementsTemplatePath) {
  $requirementsTemplate = Get-Content $requirementsTemplatePath -Raw
  foreach ($requiredText in @(
    '## Domain Context',
    'Relevant glossary terms, context boundaries, avoided synonyms, and ADR constraints',
    'Domain Context is for language and durable decisions, not implementation detail.'
  )) {
    if (-not $requirementsTemplate.Contains($requiredText)) {
      Add-Failure "requirements template must include domain context text: $requiredText"
    }
  }
} else {
  Add-Failure 'Missing plan-feature requirements template: skills/plan-feature/references/requirements-template.md'
}

if (Test-Path $taskTemplatePath) {
  $taskTemplate = Get-Content $taskTemplatePath -Raw
  foreach ($requiredText in @(
    '## Domain Context',
    '**Glossary terms:**',
    '**Avoided synonyms:**',
    '**ADR constraints:**',
    'The **Domain Context** section carries glossary and ADR constraints into the coder prompt.'
  )) {
    if (-not $taskTemplate.Contains($requiredText)) {
      Add-Failure "task template must include domain context text: $requiredText"
    }
  }
} else {
  Add-Failure 'Missing plan-feature task template: skills/plan-feature/references/task-template.md'
}

if (Test-Path $rootContextPath) {
  $rootContext = Get-Content $rootContextPath -Raw
  foreach ($requiredText in @(
    '# Context: s-kit',
    '### Phase',
    '### Phase Risk Preflight',
    '### Context',
    '### ADR'
  )) {
    if (-not $rootContext.Contains($requiredText)) {
      Add-Failure "root CONTEXT.md must define core workflow glossary term: $requiredText"
    }
  }
} else {
  Add-Failure 'Missing root glossary: CONTEXT.md'
}

foreach ($reviewerAgent in @(
  @{ Path = $specReviewerAgentPath; Label = 's-kit spec reviewer agent' },
  @{ Path = $codeReviewerAgentPath; Label = 's-kit code reviewer agent' }
)) {
  if (Test-Path $reviewerAgent.Path) {
    $reviewerAgentText = Get-Content $reviewerAgent.Path -Raw
    foreach ($requiredText in @(
      'read-only-review-contract.md',
      'You are reviewing only',
      'Reviewed Scope:',
      'If the reviewed scope is missing or too vague, stop and request the concrete git range, task diff, or file set.'
    )) {
      if (-not $reviewerAgentText.Contains($requiredText)) {
        Add-Failure "$($reviewerAgent.Label) must include read-only review safety text: $requiredText"
      }
    }
  } else {
    Add-Failure "Missing $($reviewerAgent.Label): $(Get-RelativePath $reviewerAgent.Path)"
  }
}

if ((Test-Path $specRoot) -and (Test-Path $designRoot)) {
  $specDirs = Get-ChildItem $specRoot -Directory

  foreach ($specDir in $specDirs) {
    $name = $specDir.Name
    $readme = Join-Path $specDir.FullName 'README.md'
    $manifestPath = Join-Path $specDir.FullName 'spec.json'
    $requirements = Join-Path $specDir.FullName 'requirements.md'
    $actionRequired = Join-Path $specDir.FullName 'action-required.md'
    $implementationLog = Join-Path $specDir.FullName 'implementation-log.md'
    $tasksDir = Join-Path $specDir.FullName 'tasks'
    $design = Join-Path (Join-Path $designRoot $name) 'design.md'

    foreach ($requiredPath in @($readme, $manifestPath, $requirements, $actionRequired, $implementationLog, $tasksDir, $design)) {
      if (-not (Test-Path $requiredPath)) {
        Add-Failure "Missing required workflow artifact for ${name}: $(Get-RelativePath $requiredPath)"
      }
    }

    if (-not (Test-Path $readme)) {
      continue
    }

    $readmeText = Get-Content $readme -Raw
    $expectedDesignLink = "../../design/$name/design.md"
    if (-not $readmeText.Contains($expectedDesignLink)) {
      Add-Failure "README design link must point to ${expectedDesignLink}: $(Get-RelativePath $readme)"
    }

    if (-not $readmeText.Contains('./spec.json')) {
      Add-Failure "README must link to spec.json: $(Get-RelativePath $readme)"
    }

    if (-not $readmeText.Contains('./implementation-log.md')) {
      Add-Failure "README must link to implementation-log.md: $(Get-RelativePath $readme)"
    }

    $taskLinks = [ordered]@{}
    foreach ($line in ($readmeText -split "`r?`n")) {
      if ($line -match '^- \[(?<state>[ xX])\]\s+\[(?<label>[^\]]+)\]\(\./tasks/(?<file>[^)]+\.md)\)') {
        $fileName = $Matches.file
        if ($taskLinks.Contains($fileName)) {
          Add-Failure "Duplicate task link in README for ${name}: $fileName"
        } else {
          $taskLinks[$fileName] = $Matches.state
        }
      }
    }

    if ($taskLinks.Count -eq 0) {
      Add-Failure "README has no task status links: $(Get-RelativePath $readme)"
    }

    $manifest = $null
    if (Test-Path $manifestPath) {
      try {
        $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
      } catch {
        Add-Failure "spec.json is not valid JSON for ${name}: $($_.Exception.Message)"
      }
    }

    $manifestTasksByFile = @{}
    $manifestTasksById = @{}

    if ($null -ne $manifest) {
      $expectedPaths = @{
        designPath = "docs/design/$name/design.md"
        specPath = "docs/specs/$name"
        requirementsPath = "docs/specs/$name/requirements.md"
        actionRequiredPath = "docs/specs/$name/action-required.md"
        implementationLogPath = "docs/specs/$name/implementation-log.md"
      }

      foreach ($property in $expectedPaths.Keys) {
        if ([string] $manifest.$property -ne $expectedPaths[$property]) {
          Add-Failure "spec.json ${property} must be '$($expectedPaths[$property])' for ${name}"
        }
      }

      if (-not (Test-ExactArray -Actual @($manifest.allowedTaskStatuses) -Expected $allowedStatuses)) {
        Add-Failure "spec.json allowedTaskStatuses must match the canonical status list for ${name}"
      }

      foreach ($manifestTask in @($manifest.tasks)) {
        $taskId = [string] $manifestTask.id
        $manifestFile = [string] $manifestTask.file
        $taskFileName = Get-TaskFileNameFromManifestPath $manifestFile

        if (-not $taskId) {
          Add-Failure "spec.json task is missing id for ${name}: $manifestFile"
        } elseif ($manifestTasksById.ContainsKey($taskId)) {
          Add-Failure "Duplicate task id in spec.json for ${name}: $taskId"
        } else {
          $manifestTasksById[$taskId] = $manifestTask
        }

        if (-not $manifestFile) {
          Add-Failure "spec.json task is missing file for ${name}: $taskId"
        } elseif ($manifestTasksByFile.ContainsKey($taskFileName)) {
          Add-Failure "Duplicate task file in spec.json for ${name}: $manifestFile"
        } else {
          $manifestTasksByFile[$taskFileName] = $manifestTask
        }

        if ($manifestFile -and -not $manifestFile.Replace('\', '/').StartsWith('tasks/')) {
          Add-Failure "spec.json task file must be under tasks/ for ${name}: $manifestFile"
        }

        if ([string] $manifestTask.status -notin $allowedStatuses) {
          Add-Failure "spec.json task has invalid status for ${name}: $taskId"
        }

        $manifestPhase = 0
        if (-not [int]::TryParse([string] $manifestTask.phase, [ref] $manifestPhase) -or $manifestPhase -lt 1) {
          Add-Failure "spec.json task has invalid Phase for ${name}: $taskId"
        }

        if (@($manifestTask.verificationCommands).Count -eq 0) {
          Add-Failure "spec.json task must include verificationCommands for ${name}: $taskId"
        }

        $fullTaskPath = Join-Path $specDir.FullName $manifestFile
        if ($manifestFile -and -not (Test-Path $fullTaskPath)) {
          Add-Failure "spec.json points to missing task file for ${name}: $manifestFile"
        }
      }

      $tasksByPhase = @{}
      foreach ($manifestTask in @($manifest.tasks)) {
        $Phase = [int] $manifestTask.phase
        if (-not $tasksByPhase.ContainsKey($Phase)) {
          $tasksByPhase[$Phase] = @()
        }
        $tasksByPhase[$Phase] += $manifestTask
      }

      foreach ($Phase in $tasksByPhase.Keys) {
        $owners = @{}
        foreach ($manifestTask in $tasksByPhase[$Phase]) {
          foreach ($ownedFile in (Get-TaskOwnedFiles $manifestTask)) {
            if ($owners.ContainsKey($ownedFile)) {
              Add-Failure "Same-Phase file ownership overlap in ${name} Phase ${Phase}: '$ownedFile' owned by $($owners[$ownedFile]) and $($manifestTask.id)"
            } else {
              $owners[$ownedFile] = [string] $manifestTask.id
            }
          }
        }
      }
    }

    if (-not (Test-Path $tasksDir)) {
      continue
    }

    $taskFiles = Get-ChildItem $tasksDir -Filter '*.md' -File
    $taskFileNames = @{}
    foreach ($taskFile in $taskFiles) {
      $taskFileNames[$taskFile.Name] = $taskFile
      if (-not $taskLinks.Contains($taskFile.Name)) {
        Add-Failure "Task file is not linked from README for ${name}: $(Get-RelativePath $taskFile.FullName)"
      }
      if ($null -ne $manifest -and -not $manifestTasksByFile.ContainsKey($taskFile.Name)) {
        Add-Failure "Task file is not represented in spec.json for ${name}: $(Get-RelativePath $taskFile.FullName)"
      }
    }

    foreach ($linkedTask in $taskLinks.Keys) {
      if (-not $taskFileNames.ContainsKey($linkedTask)) {
        Add-Failure "README links missing task file for ${name}: tasks/$linkedTask"
        continue
      }

      $taskPath = $taskFileNames[$linkedTask].FullName
      $taskText = Get-Content $taskPath -Raw
      $status = Get-FirstSectionValue -Content $taskText -Heading 'Status'
      $Phase = Get-FirstSectionValue -Content $taskText -Heading 'Phase'

      if ($status -notin $allowedStatuses) {
        Add-Failure "Task has invalid or missing status: $(Get-RelativePath $taskPath)"
      }

      $PhaseNumber = 0
      if (-not [int]::TryParse($Phase, [ref] $PhaseNumber) -or $PhaseNumber -lt 1) {
        Add-Failure "Task has invalid or missing Phase: $(Get-RelativePath $taskPath)"
      }

      foreach ($heading in @('## Verification Plan', '### RED', '### GREEN', '### Final Verification')) {
        if (-not (Test-Heading -Content $taskText -Heading $heading)) {
          Add-Failure "Task is missing ${heading}: $(Get-RelativePath $taskPath)"
        }
      }

      $manifestTask = $null
      if ($null -ne $manifest -and $manifestTasksByFile.ContainsKey($linkedTask)) {
        $manifestTask = $manifestTasksByFile[$linkedTask]
        if ([string] $manifestTask.status -ne $status) {
          Add-Failure "Task status does not match spec.json for ${name}: $linkedTask"
        }
        if ([int] $manifestTask.phase -ne $PhaseNumber) {
          Add-Failure "Task Phase does not match spec.json for ${name}: $linkedTask"
        }
      }

      $checkboxState = $taskLinks[$linkedTask]
      $isChecked = $checkboxState -match '[xX]'
      if ($isChecked -and $status -ne 'complete') {
        Add-Failure "README marks task complete but task status is '${status}': $linkedTask"
      }
      if ((-not $isChecked) -and $status -eq 'complete') {
        Add-Failure "Task status is complete but README checkbox is pending: $linkedTask"
      }
    }
  }

  $designDirs = Get-ChildItem $designRoot -Directory
  foreach ($designDir in $designDirs) {
    $matchingSpec = Join-Path (Join-Path $specRoot $designDir.Name) 'README.md'
    if (-not (Test-Path $matchingSpec)) {
      Add-Failure "Design folder has no matching spec README: docs/design/$($designDir.Name)/design.md"
    }
  }
}

if ($failures.Count -gt 0) {
  Write-Error "Workflow verification failed:`n$($failures -join "`n")"
}

Write-Host 'Workflow verification passed.'
