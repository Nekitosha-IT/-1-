$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$V8 = 'C:\Program Files\1cv8\8.3.27.2130\bin\1cv8.exe'
$Meta = Join-Path $Root 'EgaisCancelledTTN2026.xml'
$Dist = Join-Path $Root 'dist'
$Log = Join-Path $Dist 'EgaisCancelledTTN2026-build.log'
$OutEpf = Join-Path $Dist 'EgaisCancelledTTN2026.epf'

if (!(Test-Path -LiteralPath $V8)) {
    throw "1C executable not found: $V8"
}
if (!(Test-Path -LiteralPath $Meta)) {
    throw "Metadata XML not found: $Meta"
}

# Do not hard-code the Cyrillic form directory name here. PowerShell encoding
# can corrupt it on systems with a different console/code-page configuration.
$Modules = @(Get-ChildItem -LiteralPath (Join-Path $Root 'EgaisCancelledTTN2026') -Recurse -File -Filter 'Module.bsl' -ErrorAction SilentlyContinue)
if ($Modules.Count -eq 0) {
    throw "Form module not found under: $(Join-Path $Root 'EgaisCancelledTTN2026')"
}
if ($Modules.Count -gt 1) {
    $Module = ($Modules | Where-Object { $_.FullName -match '\\Forms\\[^\\]+\\Ext\\Form\\Module\.bsl$' } | Select-Object -First 1).FullName
    if ([string]::IsNullOrWhiteSpace($Module)) {
        $Module = $Modules[0].FullName
    }
} else {
    $Module = $Modules[0].FullName
}
Write-Host "Form module: $Module"

New-Item -ItemType Directory -Force -Path $Dist | Out-Null
Remove-Item -LiteralPath $OutEpf -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $Log -Force -ErrorAction SilentlyContinue

# Normalize old generated BSL that contains the two literal characters \n
# inside a string. 1C query text must contain actual line breaks.
$Source = [System.IO.File]::ReadAllText($Module, [System.Text.Encoding]::UTF8)
$Fixed = $Source -replace '\\n"\s*\+', '" + Символы.ПС +'
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
