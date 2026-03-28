# HTA Unified Intelligence System: concrete submission fixes

This file converts the multi-persona review into repository-side actions that should be checked before external submission of the F1000 software paper for `HTA_Unified_Intelligence_System`.

## Detectable Local State
- Documentation files detected: `README.md`, `f1000_artifacts/tutorial_walkthrough.md`.
- Environment lock or container files detected: `Dockerfile`, `requirements.txt`.
- Package manifests detected: none detected.
- Example data files detected: `f1000_artifacts/example_dataset.csv`.
- Validation artifacts detected: `f1000_artifacts/validation_summary.md`, `tests/verify_manuscript_numbers.py`, `tests/run_tests.R`, `tests/test_logic.R`.
- Detected public repository root: `https://github.com/mahmood726-cyber/hta-unified-intelligence`.
- Detected public source snapshot: Fixed public commit snapshot available at `https://github.com/mahmood726-cyber/hta-unified-intelligence/tree/5bdd7aae82681c88a1ac7b1ada9a228d08f8fc0c`.
- Detected public archive record: No project-specific DOI or Zenodo record URL was detected locally; archive registration pending.

## High-Priority Fixes
- Check that the manuscript's named example paths exist in the public archive and can be run without repository archaeology.
- Confirm that the cited repository root (`https://github.com/mahmood726-cyber/hta-unified-intelligence`) resolves to the same fixed public source snapshot used for submission.
- Archive the tagged release and insert the Zenodo DOI or record URL once it has been minted; no project-specific archive DOI was detected locally.
- Reconfirm the quoted benchmark or validation sentence after the final rerun so the narrative text matches the shipped artifacts.
- Keep the embedded WebR validation panel enabled in shipped HTML files and rerun it after any UI or calculation changes.

## Numeric Evidence Available To Quote
- `HTA_Intelligence_Manuscript_Nature.md` reports Model divergence exceeded 30% in 24 of 44 technologies (54.5%, 95% CI: 39.8–68.4%).

## Manuscript Files To Keep In Sync
- `F1000_Software_Tool_Article.md`
- `F1000_Reviewer_Rerun_Manifest.md`
- `F1000_MultiPersona_Review.md`
- `F1000_Submission_Checklist_RealReview.md` where present
- README/tutorial files and the public repository release metadata
