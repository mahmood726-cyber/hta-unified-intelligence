.PHONY: help install test test-r test-py run clean docker

help:
	@echo "HTA Unified Intelligence System - common tasks"
	@echo ""
	@echo "  make install   Install R + Python dependencies"
	@echo "  make test      Run all tests (R logic + Python units)"
	@echo "  make test-r    Run R logic tests only"
	@echo "  make test-py   Run Python unit tests only"
	@echo "  make run       Run the full pipeline (run_all_unified.sh)"
	@echo "  make docker    Build the reproducibility container"
	@echo "  make clean     Remove generated output (keeps archive)"

install:
	Rscript setup.R
	pip install -r requirements.txt

test: test-r test-py

test-r:
	Rscript tests/run_tests.R

test-py:
	pytest tests/test_python_units.py tests/test_verification_contract.py -v

run:
	bash run_all_unified.sh

docker:
	docker build -t hta-uis .

clean:
	rm -rf output/master_unified_intelligence.csv output/master_unified_intelligence.json \
	       output/tgep_results.csv output/narratives.json output/manifest.json \
	       output/figure1_tiered_truth.png output/sensitivity_analysis_results.csv \
	       output/figure2_sensitivity.png
