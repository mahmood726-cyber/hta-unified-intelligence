# HTA UNIFIED INTELLIGENCE SYSTEM: MASTER ORCHESTRATOR (V4 - REFACTORED)

$SystemDir = "C:\Models\HTA_Unified_Intelligence_System"
cd $SystemDir

# 1. Log Rotation
if (Test-Path "pipeline.log") {
    $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    if (-not (Test-Path "output/logs")) { New-Item -ItemType Directory "output/logs" | Out-Null }
    Move-Item "pipeline.log" "output/logs/pipeline_$Timestamp.log"
}

# 2. Archive Pruning
$Archives = Get-ChildItem "output/archive/master_audit_*.csv" | Sort-Object LastWriteTime -Descending
if ($Archives.Count -gt 5) {
    $Archives | Select-Object -Skip 5 | Remove-Item -Force
}

# Find R
$Rscript = Get-Command Rscript -ErrorAction SilentlyContinue
if (-not $Rscript) {
    $CommonPaths = @("C:\Program Files\R\R-*\bin\Rscript.exe", "C:\Program Files\R\R-*\bin\x64\Rscript.exe")
    $Rscript = Get-ChildItem $CommonPaths -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
}
if (-not $Rscript) { Write-Error "Rscript not found"; exit 1 }

Write-Host "--- STARTING UNIFIED HTA PIPELINE ---" -ForegroundColor Cyan

# 0. Run QA
Write-Host "[0/6] Running QA Tests..."
& $Rscript tests/test_logic.R

Write-Host "[1/6] Initial Integration..."
& $Rscript src/R/master_integration_pipeline.R

Write-Host "[2/6] TGEP Guard Rail..."
& $Rscript src/R/run_tgep_integration.R

Write-Host "[3/6] Final Integration..."
& $Rscript src/R/master_integration_pipeline.R

Write-Host "[4/6] Narrative Generation..."
python src/python/generate_narratives.py

Write-Host "[5/6] Database Archiving..."
python src/python/archive_manager.py

Write-Host "[6/6] Dashboard Refresh..."
python src/python/update_dashboard.py

python src/python/generate_manifest.py

Write-Host "--- PIPELINE COMPLETE ---" -ForegroundColor Green
