"""Unit tests for src/python/ modules (pure-function level)."""
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src" / "python"
sys.path.insert(0, str(SRC))


# generate_narratives -----------------------------------------------------

import generate_narratives as gn  # noqa: E402


def _row(**overrides):
    base = dict(
        key="CD000001",
        hta_verdict="CONDITIONAL",
        uds_score=55.4,
        inf_frac=1.0,
        loo_fragile=False,
        tgep_status="Confirmed",
        recommended_action="Conditional Approval with Monitoring",
    )
    base.update(overrides)
    return base


def test_briefing_contains_key_verdict_and_score():
    text = gn.generate_briefing(_row())
    assert "CD000001" in text
    assert "CONDITIONAL" in text
    assert "55.4" in text


def test_briefing_high_integrity_phrase():
    text = gn.generate_briefing(_row(inf_frac=1.3))
    assert "High integrity" in text


def test_briefing_low_integrity_phrase():
    text = gn.generate_briefing(_row(inf_frac=0.3))
    assert "underpowered" in text


def test_briefing_loo_fragile_warning():
    text = gn.generate_briefing(_row(loo_fragile=True))
    assert "LOO Fragile" in text


def test_briefing_tgep_status_phrasings():
    assert "confirms" in gn.generate_briefing(_row(tgep_status="Confirmed"))
    assert "precise null" in gn.generate_briefing(_row(tgep_status="Precise Null"))
    assert "inconclusive" in gn.generate_briefing(_row(tgep_status="Inconclusive"))


# query_hta ---------------------------------------------------------------

import query_hta as qh  # noqa: E402


def test_get_color_classifies_verdicts():
    assert qh.get_color("IMMUTABLE TRUTH") == qh.GREEN
    assert qh.get_color("CONDITIONAL") == qh.YELLOW
    assert qh.get_color("FRAGILE") == qh.RED
    assert qh.get_color("REJECT") == qh.RED


def test_fmt_handles_none_and_nan():
    import math

    assert qh._fmt(None) == "N/A"
    assert qh._fmt(math.nan) == "N/A"
    assert qh._fmt(1.234, ".2f") == "1.23"
    assert qh._fmt(0.5, ".0%") == "50%"


# download_assets ---------------------------------------------------------

import download_assets as da  # noqa: E402


def test_download_creates_dir_and_writes_files(tmp_path, monkeypatch):
    class FakeResponse:
        def __init__(self, content):
            self.content = content

        def raise_for_status(self):
            pass

    def fake_get(url, timeout):
        return FakeResponse(b"// stub for " + url.encode())

    monkeypatch.setattr(da.requests, "get", fake_get)
    asset_dir = tmp_path / "assets"
    failures = da.download(asset_dir=str(asset_dir), urls={"a.js": "https://x/a", "b.js": "https://x/b"})
    assert failures == []
    assert (asset_dir / "a.js").read_bytes().startswith(b"// stub")
    assert (asset_dir / "b.js").exists()


def test_download_reports_failures(tmp_path, monkeypatch):
    def fake_get(url, timeout):
        raise da.requests.exceptions.ConnectionError("offline")

    monkeypatch.setattr(da.requests, "get", fake_get)
    failures = da.download(asset_dir=str(tmp_path), urls={"x.js": "https://x/x"})
    assert failures == ["x.js"]
