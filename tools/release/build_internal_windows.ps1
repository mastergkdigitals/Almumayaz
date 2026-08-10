[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$appDirectory = Join-Path $repoRoot 'apps\desktop_flutter'
$configPath = (Resolve-Path (
    Join-Path $appDirectory 'config\internal.json'
  )).Path

Push-Location $appDirectory
try {
  & flutter build windows --release "--dart-define-from-file=$configPath"
  if ($LASTEXITCODE -ne 0) {
    throw "Flutter internal build failed with exit code $LASTEXITCODE."
  }
} finally {
  Pop-Location
}

Write-Host 'Internal build created: build\windows\x64\runner\Release\Almumayaz.exe'
