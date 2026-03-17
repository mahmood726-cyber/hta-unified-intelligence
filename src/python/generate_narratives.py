# -*- coding: utf-8 -*-
import pandas as pd
import json
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.join(SCRIPT_DIR, "..", "..", "output")
CSV_PATH = os.path.join(OUTPUT_DIR, "master_unified_intelligence.csv")
NARRATIVE_PATH = os.path.join(OUTPUT_DIR, "narratives.json")

def generate_briefing(row):
    verdict = row['hta_verdict']
    score = row['uds_score']
    text = f"**{row['key']}** has been classified as **{verdict}** (UDS: {score:.1f}). "
    
    if row['inf_frac'] > 1.0: text += "High integrity evidence base. "
    elif row['inf_frac'] < 0.5: text += "Evidence is underpowered or biased. "
        
    if row.get('loo_fragile', False): text += "Warning: Result relies on a single study (LOO Fragile). "
    
    tgep = row.get('tgep_status', 'Unknown')
    if tgep == 'Confirmed': text += "Triple-Guard Ensemble confirms the estimate. "
    elif tgep == 'Precise Null': text += "Guard Rail identifies a precise null result. "
    elif tgep == 'Inconclusive': text += "Guard Rail deems evidence inconclusive. "
        
    action = row.get('recommended_action', 'Review')
    text += f"Recommendation: *{action}*."
    return text

def run_narrative_generation():
    if not os.path.exists(CSV_PATH):
        print("Master CSV not found at", CSV_PATH)
        return

    df = pd.read_csv(CSV_PATH)
    narratives = {}
    for _, row in df.iterrows(): narratives[row['key']] = generate_briefing(row)
        
    with open(NARRATIVE_PATH, "w") as f: json.dump(narratives, f, indent=2)
    print(f"Generated {len(narratives)} briefings.")

if __name__ == "__main__":
    run_narrative_generation()
