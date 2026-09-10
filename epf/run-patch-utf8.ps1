$ErrorActionPreference = 'Stop'

$OriginalRoot = $PSScriptRoot
$Patch = Join-Path $OriginalRoot 'patch-cancelled-ttn-ui.ps1'
if (!(Test-Path -LiteralPath $Patch)) { throw "Patch script not found: $Patch" }

# Windows PowerShell 5.1 treats a UTF-8 script without BOM as ANSI.
# The patch contains Cyrillic, so execute a temporary BOM-prefixed copy.
# IMPORTANT: PSScriptRoot of the temporary copy is %TEMP%, therefore replace
# the patch's PSScriptRoot reference with the real epf directory before running it.
$bytes = [IO.File]::ReadAllBytes($Patch)
$hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF

if (!$hasBom) {
    $text = [Text.Encoding]::UTF8.GetString($bytes)
    $safeRoot = $OriginalRoot.Replace('''', '''''')
    $text = $text.Replace('$PSScriptRoot', "'$safeRoot'")
    $tmp = Join-Path $env:TEMP ('egais-patch-' + [Guid]::NewGuid().ToString('N') + '.ps1')
    try {
        [IO.File]::WriteAllText($tmp, $text, (New-Object Text.UTF8Encoding($true)))
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $tmp
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
    finally {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }
}
else {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Patch
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
