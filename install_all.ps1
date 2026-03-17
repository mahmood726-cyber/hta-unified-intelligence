Write-Host "--- HTA UNIFIED INTELLIGENCE SYSTEM INSTALLER ---" -ForegroundColor Cyan

# 1. Check Python
if (Get-Command python -ErrorAction SilentlyContinue) {
    Write-Host "✅ Python found." -ForegroundColor Green
    pip install -r requirements.txt
} else {
    Write-Error "Python not found. Please install Python 3.8+."
    exit 1
}

# 2. Check R
$Rscript = Get-Command Rscript -ErrorAction SilentlyContinue
if (-not $Rscript) {
    $CommonPaths = @("C:\Program Files\R\R-*\bin\Rscript.exe", "C:\Program Files\R\R-*\bin\x64\Rscript.exe")
    $Rscript = Get-ChildItem $CommonPaths -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
}

if ($Rscript) {
    Write-Host "✅ R found at $($Rscript.Source)" -ForegroundColor Green
    & $Rscript setup.R
} else {
    Write-Error "R not found. Please install R 4.0+."
    exit 1
}

Write-Host "--- INSTALLATION COMPLETE ---" -ForegroundColor Cyan
Write-Host "Run '.\run_all_unified.ps1' to start the system."
