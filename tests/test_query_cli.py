"""Tests for the HTA Intelligence CLI (src/python/query_hta.py).

These exercise the public entry points (load_data, find_matches, compare,
main) against the checked-in pipeline output. They assert *behaviour* — that
listing, querying, comparing, JSON emission, validation, and error exit codes
work — without asserting any scientific score value, so they never pin the
numbers the manuscript verifies elsewhere.
"""
import io
import json
import sys
from pathlib import Path

import pandas as pd
import pytest

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src" / "python"
sys.path.insert(0, str(SRC))

import query_hta  # noqa: E402

MASTER_CSV = ROOT / "output" / "master_unified_intelligence.csv"


@pytest.fixture(scope="module")
def df():
    return query_hta.load_data(str(MASTER_CSV))


def test_load_data_returns_populated_frame(df):
    assert len(df) > 0
    for col in query_hta.REQUIRED_COLUMNS:
        assert col in df.columns


def test_load_data_missing_file_raises():
    with pytest.raises(FileNotFoundError):
        query_hta.load_data(str(ROOT / "output" / "does_not_exist.csv"))


def test_load_data_missing_columns_raises(tmp_path):
    bad = tmp_path / "bad.csv"
    bad.write_text("foo,bar\n1,2\n", encoding="utf-8")
    with pytest.raises(ValueError):
        query_hta.load_data(str(bad))


def test_find_matches_case_insensitive(df):
    first_key = df.iloc[0]["key"]
    # A substring of the real key, upper-cased, must still match it.
    frag = first_key[:6].upper()
    matches = query_hta.find_matches(df, frag)
    assert first_key in set(matches["key"])


def test_find_matches_empty_query_returns_nothing(df):
    assert len(query_hta.find_matches(df, "")) == 0


def _run(argv, monkeypatch):
    """Run main() capturing stdout/stderr and the exit code."""
    out, err = io.StringIO(), io.StringIO()
    monkeypatch.setattr(sys, "stdout", out)
    monkeypatch.setattr(sys, "stderr", err)
    code = query_hta.main(argv)
    return code, out.getvalue(), err.getvalue()


def test_cli_list_json_is_valid(monkeypatch):
    code, out, _ = _run(["--list", "--json", "--data", str(MASTER_CSV)], monkeypatch)
    assert code == 0
    records = json.loads(out)
    assert isinstance(records, list) and len(records) > 0
    assert {"key", "hta_verdict", "uds_score"} <= set(records[0].keys())


def test_cli_single_query_renders_card(monkeypatch):
    key = pd.read_csv(MASTER_CSV).iloc[0]["key"]
    code, out, _ = _run([key, "--data", str(MASTER_CSV)], monkeypatch)
    assert code == 0
    assert "Technology ID:" in out
    assert "Triple-Guard Ensemble" in out


def test_cli_compare_two_ids(monkeypatch):
    keys = pd.read_csv(MASTER_CSV)["key"].tolist()
    k1, k2 = keys[0], keys[1]
    code, out, _ = _run(["--compare", k1, k2, "--data", str(MASTER_CSV)], monkeypatch)
    assert code == 0
    assert "HIGHER RANKED" in out
    assert k1 in out and k2 in out


def test_cli_compare_json(monkeypatch):
    keys = pd.read_csv(MASTER_CSV)["key"].tolist()
    code, out, _ = _run(["--compare", keys[0], keys[1], "--json", "--data", str(MASTER_CSV)],
                        monkeypatch)
    assert code == 0
    payload = json.loads(out)
    assert isinstance(payload, list) and len(payload) == 2


def test_cli_compare_wrong_arg_count_exits_2(monkeypatch):
    code, _, err = _run(["--compare", "only-one", "--data", str(MASTER_CSV)], monkeypatch)
    assert code == 2
    assert "exactly 2" in err


def test_cli_no_match_exits_3(monkeypatch):
    code, _, err = _run(["ZZ_NO_SUCH_TECH", "--data", str(MASTER_CSV)], monkeypatch)
    assert code == 3
    assert "matched" in err.lower()


def test_cli_missing_database_exits_1(monkeypatch):
    code, _, err = _run(["--list", "--data", "definitely_absent.csv"], monkeypatch)
    assert code == 1
    assert "not found" in err.lower()
