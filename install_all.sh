#!/usr/bin/env bash
# HTA UNIFIED INTELLIGENCE SYSTEM INSTALLER (Linux / macOS)
set -euo pipefail

echo "--- HTA UNIFIED INTELLIGENCE SYSTEM INSTALLER ---"

if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 not found. Install Python 3.8+." >&2
    exit 1
fi
echo "python3 found: $(python3 --version)"
python3 -m pip install -r requirements.txt

if ! command -v Rscript >/dev/null 2>&1; then
    echo "Rscript not found. Install R 4.0+." >&2
    exit 1
fi
echo "Rscript found: $(Rscript --version 2>&1 | head -n1)"
Rscript setup.R

echo "--- INSTALLATION COMPLETE ---"
echo "Run './run_all_unified.sh' to start the system."
