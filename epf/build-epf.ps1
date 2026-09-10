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

# Use only ASCII in this PowerShell file. The standard 1C administrator name is passed as Unicode bytes.
$User = [System.Text.Encoding]::Unicode.GetString([byte[]](0x10,0x04,0x34,0x04,0x3C,0x04,0x38,0x04,0x3D,0x04,0x38,0x04,0x41,0x04,0x42,0x04,0x40,0x04,0x30,0x04,0x42,0x04,0x3E,0x04,0x40,0x04))
$Password = ''
$Server = 'localhost'
$Infobase = 'roz2026'

# Avoid Start-Process ArgumentList array validation/quoting issues in Windows PowerShell 5.1.
$Arguments = 'DESIGNER /DisableStartupDialogs /S"' + $Server + '\' + $Infobase + '" /N"' + $User + '" /P"' + $Password + '" /Out"' + $Log + '" /LoadExternalDataProcessorOrReportFromFiles "' + $Meta + '" "' + $OutEpf + '"'

Write-Host "1C: $V8"
Write-Host "Infobase: ${Server}\${Infobase}"
Write-Host "Metadata: $Meta"
Write-Host "Output: $OutEpf"

$Process = Start-Process -FilePath $V8 -ArgumentList $Arguments -Wait -PassThru -NoNewWindow
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
