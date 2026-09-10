$ErrorActionPreference = 'Stop'

$EpRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Patch = Join-Path $EpRoot 'patch-cancelled-ttn-ui.ps1'
if (Test-Path -LiteralPath $Patch) {
    Write-Host 'Applying cancelled TTN UI/UTM patch...'
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Patch
    if ($LASTEXITCODE -ne 0) { throw "Patch script failed: $LASTEXITCODE" }
}

$V8 = 'C:\Program Files\1cv8\8.3.27.2130\bin\1cv8.exe'
$Root = Join-Path $EpRoot 'EgaisCancelledTTN2026'
$Meta = Join-Path $EpRoot 'EgaisCancelledTTN2026.xml'
$Dist = Join-Path $EpRoot 'dist'
$Log = Join-Path $Dist 'EgaisCancelledTTN2026-build.log'
$OutEpf = Join-Path $Dist 'EgaisCancelledTTN2026.epf'

if (!(Test-Path -LiteralPath $V8)) { throw "1C executable not found: $V8" }
if (!(Test-Path -LiteralPath $Meta)) { throw "Metadata XML not found: $Meta" }
New-Item -ItemType Directory -Force -Path $Dist | Out-Null
Remove-Item -LiteralPath $OutEpf -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $Log -Force -ErrorAction SilentlyContinue

$Server = 'localhost'
$Infobase = 'roz2026'
$User = $env:EGAIS_1C_USER
if ([string]::IsNullOrWhiteSpace($User)) { $User = Read-Host '1C infobase user name' }
$Password = $env:EGAIS_1C_PASSWORD
if ($null -eq $Password) { $Password = Read-Host '1C password (press Enter if empty)' }
if ([string]::IsNullOrWhiteSpace($User)) { throw '1C infobase user name is empty.' }

$Arguments = 'DESIGNER /DisableStartupDialogs /S"' + $Server + '\' + $Infobase + '" /N"' + $User + '" /P"' + $Password + '" /Out"' + $Log + '" /LoadExternalDataProcessorOrReportFromFiles "' + $Meta + '" "' + $OutEpf + '"'
Write-Host "1C: $V8"
Write-Host "Infobase: ${Server}\${Infobase}"
Write-Host "Metadata: $Meta"
Write-Host "Output: $OutEpf"
$Process = Start-Process -FilePath $V8 -ArgumentList $Arguments -Wait -PassThru -NoNewWindow
Write-Host "EXIT CODE: $($Process.ExitCode)"
if (Test-Path -LiteralPath $Log) { Get-Content -LiteralPath $Log -Encoding UTF8 }
if (!(Test-Path -LiteralPath $OutEpf)) { throw "EPF was not created. 1C exit code: $($Process.ExitCode)" }
$f = Get-Item -LiteralPath $OutEpf
Write-Host "SUCCESS: $($f.FullName)"
Write-Host "SIZE: $($f.Length) bytes"
