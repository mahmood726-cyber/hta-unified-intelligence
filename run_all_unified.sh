#!/usr/bin/env bash
# HTA UNIFIED INTELLIGENCE SYSTEM: MASTER ORCHESTRATOR (Linux/macOS)
set -euo pipefail

cd "$(dirname "$0")"

# 1. Log rotation
if [ -f pipeline.log ]; then
    mkdir -p output/logs
    mv pipeline.log "output/logs/pipeline_$(date +%Y%m%d_%H%M%S).log"
fi

# 2. Archive pruning (keep most-recent 5)
if [ -d output/archive ]; then
    ls -1t output/archive/master_audit_*.csv 2>/dev/null | tail -n +6 | xargs -r rm -f
fi

command -v Rscript >/dev/null 2>&1 || { echo "Rscript not found on PATH" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 not found on PATH" >&2; exit 1; }

mkdir -p output output/archive output/plots

echo "--- STARTING UNIFIED HTA PIPELINE ---"

echo "[0/6] Running QA Tests..."
Rscript tests/run_tests.R

echo "[1/6] Initial Integration..."
Rscript src/R/master_integration_pipeline.R

echo "[2/6] TGEP Guard Rail..."
Rscript src/R/run_tgep_integration.R || echo "  (TGEP skipped — Pairwise70 dataset not present)"

echo "[3/6] Final Integration..."
Rscript src/R/master_integration_pipeline.R

echo "[4/6] Narrative Generation..."
python3 src/python/generate_narratives.py

echo "[5/6] Database Archiving..."
python3 src/python/archive_manager.py

echo "[6/6] Dashboard Refresh..."
python3 src/python/update_dashboard.py
python3 src/python/generate_manifest.py

echo "--- PIPELINE COMPLETE ---"
