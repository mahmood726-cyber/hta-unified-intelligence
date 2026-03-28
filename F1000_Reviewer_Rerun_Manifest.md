# HTA Unified Intelligence System: reviewer rerun manifest

This manifest is the shortest reviewer-facing rerun path for the local software package. It lists the files that should be sufficient to recreate one worked example, inspect saved outputs, and verify that the manuscript claims remain bounded to what the repository actually demonstrates.

## Reviewer Entry Points
- Project directory: `C:\Models\HTA_Unified_Intelligence_System`.
- Preferred documentation start points: `README.md`, `f1000_artifacts/tutorial_walkthrough.md`.
- Detected public repository root: `https://github.com/mahmood726-cyber/hta-unified-intelligence`.
- Detected public source snapshot: Fixed public commit snapshot available at `https://github.com/mahmood726-cyber/hta-unified-intelligence/tree/5bdd7aae82681c88a1ac7b1ada9a228d08f8fc0c`.
- Detected public archive record: No project-specific DOI or Zenodo record URL was detected locally; archive registration pending.
- Environment capture files: `Dockerfile`, `requirements.txt`.
- Validation/test artifacts: `f1000_artifacts/validation_summary.md`, `tests/verify_manuscript_numbers.py`, `tests/run_tests.R`, `tests/test_logic.R`.

## Worked Example Inputs
- Manuscript-named example paths: `HTA_Intelligence_Manuscript_Nature.md` as the integrated technical narrative; `Unified_HTA_Dashboard.html` as the browser-facing result layer; `run_all_unified.ps1` and `master_integration_pipeline.R` for end-to-end execution; f1000_artifacts/example_dataset.csv.
- Auto-detected sample/example files: `f1000_artifacts/example_dataset.csv`.

## Expected Outputs To Inspect
- Unified Decision Scores and verdict classes.
- Guard-rail divergence summaries and fragility explanations.
- A dashboard that exposes the component engines rather than hiding them behind a black-box score.

## Minimal Reviewer Rerun Sequence
- Start with the README/tutorial files listed below and keep the manuscript paths synchronized with the public archive.
- Create the local runtime from the detected environment capture files if available: `Dockerfile`, `requirements.txt`.
- Run at least one named example path from the manuscript and confirm that the generated outputs match the saved validation materials.
- Quote one concrete numeric result from the local validation snippets below when preparing the final software paper.
- Open the browser deliverable and confirm that the embedded WebR validation panel completes successfully after the page finishes initializing.

## Local Numeric Evidence Available
- `HTA_Intelligence_Manuscript_Nature.md` reports Model divergence exceeded 30% in 24 of 44 technologies (54.5%, 95% CI: 39.8–68.4%).

## Browser Deliverables
- HTML entry points: `Unified_HTA_Dashboard.html`.
- The shipped HTML applications include embedded WebR self-validation and should be checked after any UI or calculation change.
