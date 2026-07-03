# sentinel:skip-file — hardcoded paths / templated placeholders are fixture/registry/audit-narrative data for this repo's research workflow, not portable application configuration. Same pattern as push_all_repos.py and E156 workbook files.
# -*- coding: utf-8 -*-
"""HTA Intelligence CLI.

Query, list, and compare the medical technologies scored by the HTA Unified
Intelligence System. Reads the pipeline output at
``output/master_unified_intelligence.csv`` and renders human-readable cards or
machine-readable JSON. This module only *displays* pipeline results; it never
recomputes any scientific score.
"""
import argparse
import json
import os
import sys

import pandas as pd

# ANSI colors (disabled automatically when stdout is not a TTY, see _c()).
GREEN = "\033[92m"
YELLOW = "\033[93m"
RED = "\033[91m"
RESET = "\033[0m"
BOLD = "\033[1m"

# Columns the loaded database is expected to provide. Kept as a contract so a
# malformed / truncated CSV fails loudly instead of raising a bare KeyError
# deep inside a render function.
REQUIRED_COLUMNS = ("key", "hta_verdict", "uds_score")

_DEFAULT_CSV = os.path.join("output", "master_unified_intelligence.csv")


def _use_color():
    return sys.stdout.isatty()


def _c(color, text):
    """Wrap text in an ANSI color only when writing to a terminal."""
    if not _use_color():
        return str(text)
    return f"{color}{text}{RESET}"


def load_data(path=None):
    """Load the master results CSV.

    Raises FileNotFoundError if the database is absent and ValueError if the
    file is present but missing required columns, so callers (CLI or tests) get
    an actionable error rather than a downstream KeyError.
    """
    path = path or _DEFAULT_CSV
    if not os.path.exists(path):
        raise FileNotFoundError(
            f"Database not found at '{path}'. Run the pipeline "
            "(run_all_unified.ps1) to generate output/master_unified_intelligence.csv."
        )
    df = pd.read_csv(path)
    missing = [c for c in REQUIRED_COLUMNS if c not in df.columns]
    if missing:
        raise ValueError(
            f"Database '{path}' is missing required column(s): {', '.join(missing)}."
        )
    return df


def get_color(verdict):
    if verdict == "IMMUTABLE TRUTH":
        return GREEN
    if verdict == "CONDITIONAL":
        return YELLOW
    return RED


def _fmt(row, col, spec="{}", default="N/A"):
    """Format a possibly-missing/NaN cell without raising."""
    val = row.get(col)
    if val is None or (isinstance(val, float) and pd.isna(val)):
        return default
    try:
        return spec.format(val)
    except (ValueError, TypeError):
        return str(val)


def find_matches(df, query):
    """Return the sub-DataFrame whose key contains `query` (case-insensitive)."""
    if not query:
        return df.iloc[0:0]
    return df[df["key"].str.contains(query, case=False, na=False, regex=False)]


def print_card(row):
    """Render a full metric card for one technology."""
    verdict = row["hta_verdict"]
    bar = _c(BOLD, "=" * 60)
    print(f"\n{bar}")
    print(f" {_c(BOLD, 'Technology ID:')} {row['key']}")
    print(f" {_c(BOLD, 'Verdict:')}       {_c(get_color(verdict), verdict)}")
    print(f" {_c(BOLD, 'UDS Score:')}     {_fmt(row, 'uds_score', '{:.1f}')} / 100")
    print(bar)
    print(f" {_c(BOLD, 'Evidence pillars')}")
    print(f"   Integrity (Inf Frac)   : {_fmt(row, 'inf_frac', '{:.2f}')}")
    print(f"   Stability (FPI)        : {_fmt(row, 'fpi_score', '{:.1f}')}")
    print(f"   Transportability (CTE) : {_fmt(row, 'cte_penalty', '{:.2f}')}")
    print(f"   Net Clinical Benefit   : {_fmt(row, 'ncb_raw', '{:.3f}')}")
    print(f"   Data Completeness (DCI): {_fmt(row, 'dci_score', '{:.1f}')}%")
    print(f" {_c(BOLD, 'Triple-Guard Ensemble (TGEP)')}")
    print(f"   Status                 : {_fmt(row, 'tgep_status')}")
    print(f"   Ensemble estimate      : {_fmt(row, 'tgep_est', '{:.3f}')} "
          f"(SE {_fmt(row, 'tgep_se', '{:.3f}')})")
    print(f"   Studies (k)            : {_fmt(row, 'k_studies', '{:.0f}')}")
    print(f"   Model divergence       : {_fmt(row, 'divergence_pct', '{:.1f}')}%")
    print(f"   LOO fragile            : {_fmt(row, 'loo_fragile')}")
    print(bar)
    print(f" {_c(BOLD, 'Fragility reason:')} {_fmt(row, 'fragility_reason')}")
    print(f" {_c(BOLD, 'Recommended action:')} {_fmt(row, 'recommended_action')}")
    print(f"{bar}\n")


def _print_comparison_row(label, v1, v2):
    print(f" {label:<24} | {v1:<25} | {v2:<25}")


def compare(row1, row2):
    """Render a side-by-side comparison of two technology rows."""
    print(f"\n{_c(BOLD, '=' * 80)}")
    _print_comparison_row(_c(BOLD, "METRIC"), row1["key"], row2["key"])
    print("-" * 80)
    _print_comparison_row(
        "Verdict",
        _c(get_color(row1["hta_verdict"]), row1["hta_verdict"]),
        _c(get_color(row2["hta_verdict"]), row2["hta_verdict"]),
    )
    _print_comparison_row("UDS Score", _fmt(row1, "uds_score", "{:.1f}"),
                          _fmt(row2, "uds_score", "{:.1f}"))
    _print_comparison_row("Integrity (IF)", _fmt(row1, "inf_frac", "{:.2f}"),
                          _fmt(row2, "inf_frac", "{:.2f}"))
    _print_comparison_row("Stability (FPI)", _fmt(row1, "fpi_score", "{:.1f}"),
                          _fmt(row2, "fpi_score", "{:.1f}"))
    _print_comparison_row("Transportability", _fmt(row1, "cte_penalty", "{:.2f}"),
                          _fmt(row2, "cte_penalty", "{:.2f}"))
    _print_comparison_row("Guard Rail", _fmt(row1, "tgep_status"),
                          _fmt(row2, "tgep_status"))
    print("=" * 80)
    winner = row1["key"] if float(row1["uds_score"]) >= float(row2["uds_score"]) else row2["key"]
    print(f" {_c(BOLD, 'HIGHER RANKED:')} {_c(GREEN, winner)}")
    print(f"{'=' * 80}\n")


def build_parser():
    parser = argparse.ArgumentParser(
        prog="query_hta",
        description="HTA Intelligence CLI — query the Unified Decision Score database.",
    )
    parser.add_argument("query", nargs="*", help="Technology ID(s) to query")
    parser.add_argument("--list", action="store_true", help="List all technologies")
    parser.add_argument("--compare", action="store_true",
                        help="Compare two IDs (requires exactly 2 query args)")
    parser.add_argument("--json", action="store_true",
                        help="Emit machine-readable JSON instead of formatted cards")
    parser.add_argument("--data", default=None,
                        help="Path to the master CSV (default: output/master_unified_intelligence.csv)")
    return parser


def main(argv=None):
    parser = build_parser()
    args = parser.parse_args(argv)

    try:
        df = load_data(args.data)
    except (FileNotFoundError, ValueError) as exc:
        print(_c(RED, f"Error: {exc}"), file=sys.stderr)
        return 1

    if args.list:
        cols = ["key", "hta_verdict", "uds_score"]
        if args.json:
            print(json.dumps(df[cols].to_dict(orient="records"), indent=2))
        else:
            print(df[cols].to_string(index=False))
        return 0

    if args.compare:
        if len(args.query) != 2:
            print(_c(RED, "Error: --compare requires exactly 2 technology IDs."),
                  file=sys.stderr)
            return 2
        r1 = df[df["key"] == args.query[0]]
        r2 = df[df["key"] == args.query[1]]
        if len(r1) != 1 or len(r2) != 1:
            missing = [q for q, r in ((args.query[0], r1), (args.query[1], r2)) if len(r) != 1]
            print(_c(RED, f"Error: ID(s) not found or ambiguous: {', '.join(missing)}"),
                  file=sys.stderr)
            return 3
        if args.json:
            print(json.dumps([r1.iloc[0].to_dict(), r2.iloc[0].to_dict()],
                             indent=2, default=str))
        else:
            compare(r1.iloc[0], r2.iloc[0])
        return 0

    if args.query:
        matches = find_matches(df, args.query[0])
        if len(matches) == 0:
            print(_c(YELLOW, f"No technology matched '{args.query[0]}'."),
                  file=sys.stderr)
            return 3
        if args.json:
            print(json.dumps(matches.to_dict(orient="records"), indent=2, default=str))
            return 0
        if len(matches) == 1:
            print_card(matches.iloc[0])
        else:
            print(_c(YELLOW, "Multiple matches:"))
            print(matches["key"].to_string(index=False))
        return 0

    parser.print_help()
    return 0


if __name__ == "__main__":
    sys.exit(main())
