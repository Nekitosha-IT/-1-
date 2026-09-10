$ErrorActionPreference = 'Stop'

$Patch = Join-Path $PSScriptRoot 'patch-cancelled-ttn-ui.ps1'
if (!(Test-Path -LiteralPath $Patch)) { throw "Patch script not found: $Patch" }

# Windows PowerShell 5.1 treats a UTF-8 script without BOM as ANSI.
# The patch contains Cyrillic, so execute a temporary BOM-prefixed copy.
$bytes = [IO.File]::ReadAllBytes($Patch)
$hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF

if (!$hasBom) {
    $tmp = Join-Path $env:TEMP ('egais-patch-' + [Guid]::NewGuid().ToString('N') + '.ps1')
    try {
        $bom = [Text.Encoding]::UTF8.GetPreamble()
        $out = New-Object byte[] ($bom.Length + $bytes.Length)
        [Array]::Copy($bom, 0, $out, 0, $bom.Length)
        [Array]::Copy($bytes, 0, $out, $bom.Length, $bytes.Length)
        [IO.File]::WriteAllBytes($tmp, $out)
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
