# -*- coding: utf-8 -*-
import pandas as pd
import sys
import argparse
import os

# Colors
GREEN = "\033[92m"
YELLOW = "\033[93m"
RED = "\033[91m"
RESET = "\033[0m"
BOLD = "\033[1m"

def load_data():
    path = os.path.join("output", "master_unified_intelligence.csv")
    if not os.path.exists(path):
        print(f"{RED}Error: Database not found.{RESET}")
        sys.exit(1)
    return pd.read_csv(path)

def get_color(verdict):
    return GREEN if verdict == "IMMUTABLE TRUTH" else (YELLOW if verdict == "CONDITIONAL" else RED)

def print_card(row):
    verdict = row['hta_verdict']
    print(f"\n{BOLD}{'='*60}{RESET}")
    print(f" {BOLD}Technology ID:{RESET} {row['key']}")
    print(f" {BOLD}Verdict:{RESET}       {get_color(verdict)}{verdict}{RESET}")
    print(f" {BOLD}UDS Score:{RESET}     {row['uds_score']:.1f} / 100")
    print(f"{BOLD}{'='*60}{RESET}")
    # ... (Rest of card logic similar to before)

def print_comparison(row1, row2):
    print(f"\n{BOLD}{'='*80}{RESET}")
    print(f" {BOLD}METRIC{RESET:<25} | {row1['key']:<25} | {row2['key']:<25}")
    print(f"{'-'*80}")
    
    # Verdict
    c1 = get_color(row1['hta_verdict'])
    c2 = get_color(row2['hta_verdict'])
    print(f" {BOLD}Verdict{RESET:<25} | {c1}{row1['hta_verdict']:<25}{RESET} | {c2}{row2['hta_verdict']:<25}{RESET}")
    
    # Score
    print(f" {BOLD}UDS Score{RESET:<25} | {row1['uds_score']:<25.1f} | {row2['uds_score']:<25.1f}")
    
    # Pillars
    print(f" Integrity (IF){RESET:<25} | {row1['inf_frac']:<25.2f} | {row2['inf_frac']:<25.2f}")
    print(f" Stability (FPI){RESET:<25} | {row1['fpi_score']:<25.1f} | {row2['fpi_score']:<25.1f}")
    print(f" Transportability{RESET:<25} | {row1['cte_penalty']:<25.2f} | {row2['cte_penalty']:<25.2f}")
    
    # Guard
    print(f" Guard Rail{RESET:<25} | {row1.get('tgep_status', 'N/A'):<25} | {row2.get('tgep_status', 'N/A'):<25}")
    
    # Winner
    winner = row1['key'] if row1['uds_score'] > row2['uds_score'] else row2['key']
    print(f"{'='*80}")
    print(f" {BOLD}HIGHER RANKED:{RESET} {GREEN}{winner}{RESET}")
    print(f"{'='*80}\n")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="HTA Intelligence CLI")
    parser.add_argument("query", nargs="*", help="Technology ID(s) to query")
    parser.add_argument("--list", action="store_true", help="List all technologies")
    parser.add_argument("--compare", action="store_true", help="Compare two IDs")
    args = parser.parse_args()

    df = load_data()

    if args.list:
        print(df[['key', 'hta_verdict', 'uds_score']].to_string(index=False))
    elif args.compare:
        if len(args.query) != 2:
            print(f"{RED}Error: Compare requires exactly 2 IDs.{RESET}")
        else:
            r1 = df[df['key'] == args.query[0]]
            r2 = df[df['key'] == args.query[1]]
            if len(r1) == 1 and len(r2) == 1:
                print_comparison(r1.iloc[0], r2.iloc[0])
            else:
                print(f"{RED}Error: One or both IDs not found.{RESET}")
    elif args.query:
        matches = df[df['key'].str.contains(args.query[0], case=False)]
        if len(matches) == 1: print_card(matches.iloc[0])
        else: print(f"{YELLOW}Matches:{RESET}\n{matches['key'].to_string(index=False)}")
    else:
        parser.print_help()
