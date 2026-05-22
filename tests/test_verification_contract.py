import shutil
import subprocess
import sys
from pathlib import Path

import pytest


ROOT = Path(__file__).resolve().parents[1]


def _artefacts_present():
    return (
        (ROOT / "output" / "master_unified_intelligence.csv").exists()
        and (ROOT / "output" / "tgep_results.csv").exists()
    )


def test_manuscript_numbers_match_checked_outputs():
    if not _artefacts_present():
        pytest.skip("Pipeline output not present; run run_all_unified.sh first")
    subprocess.run(
        [sys.executable, "tests/verify_manuscript_numbers.py"],
        cwd=ROOT,
        check=True,
    )


def test_dashboard_and_required_outputs_exist():
    # Source-tree files that must always be present
    required_in_source = [
        "Unified_HTA_Dashboard.html",
        "src/R/TGEP.R",
        "tests/test_logic.R",
    ]
    missing_source = [p for p in required_in_source if not (ROOT / p).exists()]
    assert missing_source == [], f"Missing source files: {missing_source}"

    # Generated outputs — only assert when a pipeline run has happened
    if not _artefacts_present():
        pytest.skip("Pipeline output not present; run run_all_unified.sh first")
    required_generated = [
        "output/master_unified_intelligence.csv",
        "output/tgep_results.csv",
        "output/manifest.json",
    ]
    missing_generated = [p for p in required_generated if not (ROOT / p).exists()]
    assert missing_generated == [], f"Missing generated files: {missing_generated}"


def test_r_logic_suite_passes_when_rscript_is_available():
    rscript = shutil.which("Rscript")
    if rscript is None:
        pytest.skip("Rscript is not installed in this environment")
    subprocess.run([rscript, "tests/run_tests.R"], cwd=ROOT, check=True)
