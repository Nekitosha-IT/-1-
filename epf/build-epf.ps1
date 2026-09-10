$ErrorActionPreference = 'Stop'

# Main build entry point for the cancelled EGAIS TTN processor.
# Kept under the generic name so the user can always run:
#   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\build-epf.ps1

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Builder = Join-Path $Root 'build-cancelled-ttn.ps1'

if (!(Test-Path -LiteralPath $Builder)) {
    throw "Build script not found: $Builder"
}

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Builder
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
