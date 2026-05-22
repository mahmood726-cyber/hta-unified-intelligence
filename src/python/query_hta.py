# sentinel:skip-file — hardcoded paths / templated placeholders are fixture/registry/audit-narrative data for this repo's research workflow, not portable application configuration. Same pattern as push_all_repos.py and E156 workbook files.
# -*- coding: utf-8 -*-
import argparse
import os
import sys

import pandas as pd

GREEN = "\033[92m"
YELLOW = "\033[93m"
RED = "\033[91m"
RESET = "\033[0m"
BOLD = "\033[1m"


def load_data():
    path = os.path.join("output", "master_unified_intelligence.csv")
    if not os.path.exists(path):
        print(f"{RED}Error: Database not found at {path}.{RESET}")
        sys.exit(1)
    return pd.read_csv(path)


def get_color(verdict):
    if verdict == "IMMUTABLE TRUTH":
        return GREEN
    if verdict == "CONDITIONAL":
        return YELLOW
    return RED


def _fmt(value, spec=".2f"):
    if value is None or pd.isna(value):
        return "N/A"
    return format(value, spec)


def _label(text, width=20):
    return f"{BOLD}{text:<{width}}{RESET}"


def print_card(row):
    verdict = row["hta_verdict"]
    print(f"\n{BOLD}{'=' * 60}{RESET}")
    print(f" {_label('Technology ID:')} {row['key']}")
    print(f" {_label('Verdict:')} {get_color(verdict)}{verdict}{RESET}")
    print(f" {_label('UDS Score:')} {_fmt(row['uds_score'], '.1f')} / 100")
    print(f" {_label('DCI Score:')} {_fmt(row.get('dci_score'), '.0f')}%")
    print(f"{BOLD}{'-' * 60}{RESET}")
    print(f" {_label('Integrity (IF):')} {_fmt(row.get('inf_frac'))}")
    print(f" {_label('Stability (FPI):')} {_fmt(row.get('fpi_score'), '.1f')}")
    print(f" {_label('Transportability:')} {_fmt(row.get('cte_penalty'))}")
    print(f" {_label('Net Benefit:')} {_fmt(row.get('ncb_raw'))}")
    print(f" {_label('Guard Rail:')} {row.get('tgep_status', 'N/A')}")
    print(f" {_label('Action:')} {row.get('recommended_action', 'N/A')}")
    print(f"{BOLD}{'=' * 60}{RESET}\n")


def print_comparison(row1, row2):
    col = 25
    bar = "=" * (col * 3 + 6)
    print(f"\n{BOLD}{bar}{RESET}")
    print(f" {_label('METRIC', col)} | {row1['key']:<{col}} | {row2['key']:<{col}}")
    print("-" * (col * 3 + 6))

    c1, c2 = get_color(row1["hta_verdict"]), get_color(row2["hta_verdict"])
    print(
        f" {_label('Verdict', col)} | "
        f"{c1}{row1['hta_verdict']:<{col}}{RESET} | "
        f"{c2}{row2['hta_verdict']:<{col}}{RESET}"
    )
    print(f" {_label('UDS Score', col)} | {row1['uds_score']:<{col}.1f} | {row2['uds_score']:<{col}.1f}")
    print(f" {_label('Integrity (IF)', col)} | {_fmt(row1.get('inf_frac')):<{col}} | {_fmt(row2.get('inf_frac')):<{col}}")
    print(f" {_label('Stability (FPI)', col)} | {_fmt(row1.get('fpi_score'), '.1f'):<{col}} | {_fmt(row2.get('fpi_score'), '.1f'):<{col}}")
    print(f" {_label('Transportability', col)} | {_fmt(row1.get('cte_penalty')):<{col}} | {_fmt(row2.get('cte_penalty')):<{col}}")
    print(f" {_label('Guard Rail', col)} | {str(row1.get('tgep_status', 'N/A')):<{col}} | {str(row2.get('tgep_status', 'N/A')):<{col}}")

    winner = row1["key"] if row1["uds_score"] > row2["uds_score"] else row2["key"]
    print(bar)
    print(f" {BOLD}HIGHER RANKED:{RESET} {GREEN}{winner}{RESET}")
    print(f"{bar}\n")


def main():
    parser = argparse.ArgumentParser(description="HTA Intelligence CLI")
    parser.add_argument("query", nargs="*", help="Technology ID(s) to query")
    parser.add_argument("--list", action="store_true", help="List all technologies")
    parser.add_argument("--compare", action="store_true", help="Compare two IDs")
    args = parser.parse_args()

    df = load_data()

    if args.list:
        print(df[["key", "hta_verdict", "uds_score"]].to_string(index=False))
        return

    if args.compare:
        if len(args.query) != 2:
            print(f"{RED}Error: --compare requires exactly 2 IDs.{RESET}")
            sys.exit(2)
        r1 = df[df["key"] == args.query[0]]
        r2 = df[df["key"] == args.query[1]]
        if len(r1) == 1 and len(r2) == 1:
            print_comparison(r1.iloc[0], r2.iloc[0])
        else:
            print(f"{RED}Error: One or both IDs not found.{RESET}")
            sys.exit(2)
        return

    if args.query:
        matches = df[df["key"].str.contains(args.query[0], case=False, na=False)]
        if len(matches) == 1:
            print_card(matches.iloc[0])
        elif len(matches) == 0:
            print(f"{YELLOW}No matches for '{args.query[0]}'.{RESET}")
        else:
            print(f"{YELLOW}Matches:{RESET}\n{matches['key'].to_string(index=False)}")
        return

    parser.print_help()


if __name__ == "__main__":
    main()
