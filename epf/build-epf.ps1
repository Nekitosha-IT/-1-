$ErrorActionPreference = 'Stop'

$V8 = 'C:\Program Files\1cv8\8.3.27.2130\bin\1cv8.exe'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Dist = Join-Path $Root 'dist'
$Log = Join-Path $Dist 'build.log'
$MetaName = 'EgaisRequestRepealWB2026.xml'
$OutName = 'EgaisRequestRepealWB2026.epf'

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

# Build the Russian 1C user name without putting non-ASCII characters into this .ps1.
$User = -join ([int[]](0x0410,0x0434,0x043C,0x0438,0x043D,0x0438,0x0441,0x0442,0x0440,0x0430,0x0442,0x043E,0x0440) | ForEach-Object { [char]$_ })
$Password = ''
$Server = 'localhost'
$Infobase = 'roz2026'

$arguments = @(
    'DESIGNER'
    "/S${Server}\${Infobase}"
    '/N', $User
    '/P', $Password
    '/DisableStartupDialogs'
    '/Out', $Log
    '/LoadExternalDataProcessorOrReportFromFiles', $Meta, $OutEpf
)

Write-Host "1C: $V8"
Write-Host "Infobase: ${Server}\${Infobase}"
Write-Host "Metadata: $Meta"
Write-Host "Output: $OutEpf"

$Process = Start-Process -FilePath $V8 -ArgumentList $arguments -Wait -PassThru -NoNewWindow
$exitCode = $Process.ExitCode

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
