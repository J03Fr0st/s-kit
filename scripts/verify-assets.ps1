$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
  param([string] $Message)
  $script:failures.Add($Message) | Out-Null
}

$svgPath = Join-Path $root 'assets/s-kit-small.svg'
$pngPath = Join-Path $root 'assets/app-icon.png'

function Get-Sha256 {
  param([string] $Path)

  $stream = [System.IO.File]::OpenRead($Path)
  try {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
      return ([System.BitConverter]::ToString($sha.ComputeHash($stream)) -replace '-', '')
    } finally {
      $sha.Dispose()
    }
  } finally {
    $stream.Dispose()
  }
}

if (-not (Test-Path $svgPath)) {
  Add-Failure 'Missing assets/s-kit-small.svg.'
} else {
  $svg = Get-Content $svgPath -Raw
  foreach ($required in @('s-kit-owned-mark-v1', '#14B8A6', '#F59E0B', '#0F172A')) {
    if (-not $svg.Contains($required)) {
      Add-Failure "assets/s-kit-small.svg must contain $required."
    }
  }
}

if (-not (Test-Path $pngPath)) {
  Add-Failure 'Missing assets/app-icon.png.'
} else {
  Add-Type -AssemblyName System.Drawing
  $bitmap = [System.Drawing.Bitmap]::FromFile($pngPath)
  try {
    if ($bitmap.Width -ne 2134 -or $bitmap.Height -ne 2134) {
      Add-Failure "assets/app-icon.png must stay 2134x2134. Found $($bitmap.Width)x$($bitmap.Height)."
    }

    $corner = $bitmap.GetPixel(0, 0)
    if ($corner.A -ne 0) {
      Add-Failure 'assets/app-icon.png must keep transparent corners.'
    }

    $samplePoints = @(
      @([int]($bitmap.Width * 0.35), [int]($bitmap.Height * 0.64)),
      @([int]($bitmap.Width * 0.65), [int]($bitmap.Height * 0.36)),
      @([int]($bitmap.Width * 0.50), [int]($bitmap.Height * 0.50))
    )
    $coloredSampleCount = 0
    foreach ($point in $samplePoints) {
      $pixel = $bitmap.GetPixel($point[0], $point[1])
      if ($pixel.A -gt 0 -and ($pixel.R -ne $pixel.G -or $pixel.G -ne $pixel.B)) {
        $coloredSampleCount++
      }
    }

    if ($coloredSampleCount -lt 2) {
      Add-Failure 'assets/app-icon.png must use the s-kit color mark, not the old monochrome asset.'
    }
  } finally {
    $bitmap.Dispose()
  }
}

$oldPngHash = 'B7477EB39B5109617FE37E51DD65D8BDD8DFF6C40FDA49ADFBC21EEC445777EE'
if ((Test-Path $pngPath) -and (Get-Sha256 $pngPath) -eq $oldPngHash) {
  Add-Failure 'assets/app-icon.png still matches the old upstream hash.'
}

if ($failures.Count -gt 0) {
  Write-Error "Asset verification failed:`n$($failures -join "`n")"
}

Write-Host 'Asset verification passed.'
