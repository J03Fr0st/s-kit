$ErrorActionPreference = 'Stop'

$bannedBranding = 'Superpowers|superpowers|using-superpowers|\bobra\b|Jesse Vincent|fsck\.com|Prime Radiant|primeradiant'
$bannedSpecPaths = 'docs/s-kit|docs/superpowers|specs/\{feature\}|`specs/| specs/|docs/specs/[^/\s]+\.md|docs/design/[^/\s]+\.md'

$brandingMatches = & rg -n $bannedBranding -g '!scripts/verify-branding.ps1' -g '!NOTICE.md'
if ($LASTEXITCODE -eq 0) {
  Write-Error "Banned branding references remain:`n$brandingMatches"
}
if ($LASTEXITCODE -gt 1) {
  exit $LASTEXITCODE
}

$specPathMatches = & rg -n $bannedSpecPaths -g '!scripts/verify-branding.ps1'
if ($LASTEXITCODE -eq 0) {
  Write-Error "Old spec path references remain:`n$specPathMatches"
}
if ($LASTEXITCODE -gt 1) {
  exit $LASTEXITCODE
}

Write-Host 'Branding and spec path verification passed.'
