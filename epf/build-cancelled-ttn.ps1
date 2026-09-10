$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$V8 = 'C:\Program Files\1cv8\8.3.27.2130\bin\1cv8.exe'
$Meta = Join-Path $Root 'EgaisCancelledTTN2026.xml'
$Module = Join-Path $Root 'EgaisCancelledTTN2026\Forms\Форма\Ext\Form\Module.bsl'
$Dist = Join-Path $Root 'dist'
$Log = Join-Path $Dist 'EgaisCancelledTTN2026-build.log'
$OutEpf = Join-Path $Dist 'EgaisCancelledTTN2026.epf'

if (!(Test-Path -LiteralPath $V8)) {
    throw "1C executable not found: $V8"
}
if (!(Test-Path -LiteralPath $Meta)) {
    throw "Metadata XML not found: $Meta"
}
if (!(Test-Path -LiteralPath $Module)) {
    throw "Form module not found: $Module"
}

New-Item -ItemType Directory -Force -Path $Dist | Out-Null
Remove-Item -LiteralPath $OutEpf -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $Log -Force -ErrorAction SilentlyContinue

# 1C query text must contain real line breaks (or use Символы.ПС).
# Older generated source used the two characters \n inside BSL string literals.
# Normalize those sequences before Designer imports the external processor.
$Source = [System.IO.File]::ReadAllText($Module, [System.Text.Encoding]::UTF8)
$Fixed = $Source -replace '\\n" \+', '" + Символы.ПС +'
if ($Fixed -ne $Source) {
    $Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Module, $Fixed, $Utf8NoBom)
    Write-Host 'Patched BSL query line breaks: literal \\n -> Символы.ПС' -ForegroundColor Yellow
}

$Server = 'localhost'
$Infobase = 'roz2026'
$User = $env:EGAIS_1C_USER
if ([string]::IsNullOrWhiteSpace($User)) {
    $User = Read-Host '1C infobase user name'
}
$Password = $env:EGAIS_1C_PASSWORD
if ($null -eq $Password) {
    $Password = Read-Host '1C password (press Enter if empty)'
}
if ([string]::IsNullOrWhiteSpace($User)) {
    throw '1C infobase user name is empty.'
}

Write-Host 'Building EgaisCancelledTTN2026...' -ForegroundColor Cyan
Write-Host "1C: $V8"
Write-Host "Infobase: ${Server}\${Infobase}"
Write-Host "Metadata: $Meta"
Write-Host "Output: $OutEpf"

$Arguments = 'DESIGNER /DisableStartupDialogs /S"' + $Server + '\' + $Infobase + '" /N"' + $User + '" /P"' + $Password + '" /Out"' + $Log + '" /LoadExternalDataProcessorOrReportFromFiles "' + $Meta + '" "' + $OutEpf + '"'
$Process = Start-Process -FilePath $V8 -ArgumentList $Arguments -Wait -PassThru -NoNewWindow
$ExitCode = $Process.ExitCode

Write-Host "EXIT CODE: $ExitCode"

if (Test-Path -LiteralPath $Log) {
    Write-Host '--- build log ---'
    Get-Content -LiteralPath $Log -Encoding UTF8
    Write-Host '--- end build log ---'
}

if (!(Test-Path -LiteralPath $OutEpf)) {
    throw "EPF was not created. 1C exit code: $ExitCode"
}

$File = Get-Item -LiteralPath $OutEpf
Write-Host ''
Write-Host 'SUCCESS: EPF created.' -ForegroundColor Green
Write-Host "EPF: $($File.FullName)"
Write-Host "SIZE: $($File.Length) bytes"
