# Changelog

## 2026-05-20
### Fixed
- README: corrupted `??` glyphs replaced, paths updated to reflect actual `src/R/` and `src/python/` layout.
- `src/python/query_hta.py`: column-alignment bug where ANSI reset string was width-formatted instead of the label; `print_card` was a stub and is now complete.
- `src/python/update_dashboard.py`: replaced deprecated `<marquee>` tag with CSS-animated ticker.
- `src/python/download_assets.py`: added request timeout, removed non-ASCII status glyphs that broke on default Windows code pages.
- `Dockerfile`: corrected entrypoint (was running a non-existent root script), bumped base image to `rocker/tidyverse:4.3.2`, cleaned apt cache.
- GitHub Actions workflow: fixed stale root paths, bumped `actions/checkout` and `upload-artifact` to v4, split into `test` and `pipeline` jobs, added PR triggers.

### Added
- `run_all_unified.sh` — Linux/macOS orchestrator equivalent to `run_all_unified.ps1`.
- `setup.R` now installs `metafor`, `jsonlite`, and `testthat` (previously missing despite being used).
- `requirements.txt` now includes `requests` and `pytest` (previously missing despite being used).
- README: documented configuration, environment variables, tests, Docker usage, and pipeline stages.

## 2026-03-06
- Added F1000 software tool manuscript package.
- Added real-review-aligned submission checklist.
- Added metadata files for reproducibility readiness.
