$ErrorActionPreference = 'Stop'

$bannedBranding = 'Superpowers|superpowers|using-superpowers|\bobra\b|Jesse Vincent|fsck\.com|Prime Radiant|primeradiant'
$bannedSpecPaths = 'docs/s-kit|docs/superpowers|specs/\{feature\}|`specs/| specs/|docs/specs/[^/\s]+\.md|docs/design/[^/\s]+\.md'

# NOTICE.md, research/comparison notes, dated design/spec artifacts, generated
# graph output, and intentional negative test assertions can legitimately name
# upstream projects. The ban still applies to all shipped product surfaces.
$commonExclusions = @(
  '-g', '!scripts/verify-branding.ps1',
  '-g', '!NOTICE.md',
  '-g', '!docs/future-development-research.md',
  '-g', '!docs/comparable-project-enhancements.md',
  '-g', '!docs/design/**',
  '-g', '!docs/specs/**',
  '-g', '!graphify-out/**'
)

$brandingExclusions = $commonExclusions + @(
  '-g', '!tests/brainstorm-server/start-server.test.sh'
)

$brandingMatches = & rg -n $bannedBranding @brandingExclusions
if ($LASTEXITCODE -eq 0) {
  Write-Error "Banned branding references remain:`n$brandingMatches"
}
if ($LASTEXITCODE -gt 1) {
  exit $LASTEXITCODE
}

$specPathMatches = & rg -n $bannedSpecPaths @commonExclusions
if ($LASTEXITCODE -eq 0) {
  Write-Error "Old spec path references remain:`n$specPathMatches"
}
if ($LASTEXITCODE -gt 1) {
  exit $LASTEXITCODE
}

Write-Host 'Branding and spec path verification passed.'
