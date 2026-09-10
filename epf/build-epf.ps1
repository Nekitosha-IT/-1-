$ErrorActionPreference = 'Stop'

# 1C executable. Change only if another platform version is installed.
$V8 = 'C:\Program Files\1cv8\8.3.27.2130\bin\1cv8.exe'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Dist = Join-Path $Root 'dist'
$Log = Join-Path $Dist 'build.log'

if (!(Test-Path -LiteralPath $V8)) {
    throw "1C executable not found: $V8"
}

New-Item -ItemType Directory -Force -Path $Dist | Out-Null

$meta = Get-ChildItem -LiteralPath $Root -Filter '*.xml' -File | Where-Object { $_.Name -notmatch '^Form' } | Select-Object -First 1
if ($null -eq $meta) {
    throw 'External processor metadata XML was not found in the epf directory.'
}

$outEpf = Join-Path $Dist 'EgaisRepealDecision.epf'
if (Test-Path -LiteralPath $outEpf) {
    Remove-Item -LiteralPath $outEpf -Force
}

$arguments = @(
    'DESIGNER'
    '/DisableStartupDialogs'
    '/Out', $Log
    '/LoadExternalDataProcessorOrReportFromFiles', $meta.FullName, $outEpf
)

Write-Host "1C: $V8"
Write-Host "Metadata: $($meta.FullName)"
Write-Host "Output: $outEpf"

& $V8 @arguments
$exitCode = $LASTEXITCODE

if ($exitCode -ne 0) {
    Write-Host "1C Designer exit code: $exitCode"
    if (Test-Path -LiteralPath $Log) { Get-Content -LiteralPath $Log -Encoding UTF8 }
    throw 'EPF build failed.'
}

if (!(Test-Path -LiteralPath $outEpf)) {
    if (Test-Path -LiteralPath $Log) { Get-Content -LiteralPath $Log -Encoding UTF8 }
    throw '1C Designer returned success but the EPF file was not created.'
}

Write-Host ''
Write-Host 'SUCCESS: EPF created.'
Write-Host "EPF: $outEpf"
Write-Host "SIZE: $((Get-Item -LiteralPath $outEpf).Length) bytes"
