import shutil
import subprocess
import sys
from pathlib import Path

import pytest


ROOT = Path(__file__).resolve().parents[1]


def test_manuscript_numbers_match_checked_outputs():
    subprocess.run(
        [sys.executable, "tests/verify_manuscript_numbers.py"],
        cwd=ROOT,
        check=True,
    )


def test_dashboard_and_required_outputs_exist():
    required = [
        "Unified_HTA_Dashboard.html",
        "output/master_unified_intelligence.csv",
        "output/tgep_results.csv",
        "output/manifest.json",
        "src/R/TGEP.R",
        "tests/test_logic.R",
    ]
    missing = [path for path in required if not (ROOT / path).exists()]
    assert missing == []


def test_r_logic_suite_passes_when_rscript_is_available():
    rscript = shutil.which("Rscript")
    if rscript is None:
        pytest.skip("Rscript is not installed in this environment")
    subprocess.run([rscript, "tests/run_tests.R"], cwd=ROOT, check=True)
