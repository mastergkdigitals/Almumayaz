[CmdletBinding()]
param(
  [Parameter(Mandatory = $false)]
  [string]$ConfigPath
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$appDirectory = Join-Path $repoRoot 'apps\desktop_flutter'
if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
  $ConfigPath = Join-Path $appDirectory 'config\customer.example.json'
}
$resolvedConfigPath = (Resolve-Path -LiteralPath $ConfigPath).Path
$configuration = Get-Content -LiteralPath $resolvedConfigPath -Raw |
  ConvertFrom-Json
$edition = [string]$configuration.APP_EDITION
$showDesignSystem = [string]$configuration.SHOW_DESIGN_SYSTEM
$enabledModules = [string]$configuration.ENABLED_MODULES
$applicationTitle = [string]$configuration.APP_TITLE
$companyName = [string]$configuration.COMPANY_NAME

if ($edition.ToLowerInvariant() -ne 'customer') {
  throw 'Customer builds require APP_EDITION to be customer.'
}
if ($showDesignSystem.ToLowerInvariant() -ne 'false') {
  throw 'Customer configuration must set SHOW_DESIGN_SYSTEM to false.'
}
if ([string]::IsNullOrWhiteSpace($applicationTitle)) {
  throw 'Customer configuration requires APP_TITLE.'
}
if ([string]::IsNullOrWhiteSpace($companyName)) {
  throw 'Customer configuration requires COMPANY_NAME.'
}
if ([string]::IsNullOrWhiteSpace($enabledModules)) {
  throw 'Customer configuration requires an explicit ENABLED_MODULES list.'
}

$allowedModules = @(
  'purchases',
  'sales',
  'cashbox',
  'parties',
  'company',
  'warehouses',
  'reports',
  'settings',
  'about'
)
$requestedModules = @(
  $enabledModules.Split(',') |
    ForEach-Object { $_.Trim().ToLowerInvariant() } |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
)
$unknownModules = @(
  $requestedModules | Where-Object { $allowedModules -notcontains $_ }
)
if ($unknownModules.Count -gt 0) {
  throw "Unknown customer modules: $($unknownModules -join ', ')."
}

Push-Location $appDirectory
try {
  & flutter build windows --release `
    "--dart-define-from-file=$resolvedConfigPath"
  if ($LASTEXITCODE -ne 0) {
    throw "Flutter customer build failed with exit code $LASTEXITCODE."
  }
} finally {
  Pop-Location
}

Write-Host 'Customer build created: build\windows\x64\runner\Release\Almumayaz.exe'
