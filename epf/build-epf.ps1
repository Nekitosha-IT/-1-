$ErrorActionPreference = 'Stop'

$V8 = 'C:\Program Files\1cv8\8.3.27.2130\bin\1cv8.exe'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Dist = Join-Path $Root 'dist'
$Log = Join-Path $Dist 'build.log'
$MetaName = 'EgaisRequestRepealWB2026.xml'
$OutName = 'EgaisRequestRepealWB2026.epf'
$Server = 'localhost\roz2026'
$User = 'Администратор'
$Password = ''

if (!(Test-Path -LiteralPath $V8)) {
    throw "1C executable not found: $V8"
}

$Meta = Join-Path $Root $MetaName
if (!(Test-Path -LiteralPath $Meta)) {
    throw "Metadata XML not found: $Meta"
}

New-Item -ItemType Directory -Force -Path $Dist | Out-Null
$OutEpf = Join-Path $Dist $OutName
Remove-Item -LiteralPath $OutEpf -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $Log -Force -ErrorAction SilentlyContinue

$arguments = @(
    'DESIGNER'
    '/DisableStartupDialogs'
    "/S$Server"
    "/N$User"
    "/P$Password"
    '/Out', $Log
    '/LoadExternalDataProcessorOrReportFromFiles', $Meta, $OutEpf
)

Write-Host "1C: $V8"
Write-Host "Infobase: $Server"
Write-Host "Metadata: $Meta"
Write-Host "Output: $OutEpf"

$process = Start-Process -FilePath $V8 -ArgumentList $arguments -Wait -PassThru
$exitCode = $process.ExitCode

Write-Host "EXIT CODE: $exitCode"

if (Test-Path -LiteralPath $Log) {
    Write-Host '--- build.log ---'
    Get-Content -LiteralPath $Log -Encoding UTF8
    Write-Host '--- end build.log ---'
}

if (!(Test-Path -LiteralPath $OutEpf)) {
    throw "EPF was not created. 1C exit code: $exitCode"
}

$f = Get-Item -LiteralPath $OutEpf
Write-Host ''
Write-Host 'SUCCESS: EPF created.' -ForegroundColor Green
Write-Host "EPF: $($f.FullName)"
Write-Host "SIZE: $($f.Length) bytes"
