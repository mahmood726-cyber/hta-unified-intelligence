import sqlite3
import pandas as pd
import os
import datetime

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.join(SCRIPT_DIR, "..", "..", "output")
DB_PATH = os.path.join(OUTPUT_DIR, "hta_history.db")
CSV_PATH = os.path.join(OUTPUT_DIR, "master_unified_intelligence.csv")

def init_db():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("CREATE TABLE IF NOT EXISTS audit_log (timestamp TEXT, key TEXT, uds_score REAL, hta_verdict TEXT, dci_score REAL, divergence_pct REAL, tgep_status TEXT)")
    conn.commit()
    conn.close()

def archive_current_run():
    if not os.path.exists(CSV_PATH): return
    df = pd.read_csv(CSV_PATH)
    conn = sqlite3.connect(DB_PATH)
    df['timestamp'] = datetime.datetime.now().isoformat()
    cols = ['timestamp', 'key', 'uds_score', 'hta_verdict', 'dci_score', 'divergence_pct', 'tgep_status']
    for c in cols: 
        if c not in df.columns: df[c] = None
    df[cols].to_sql('audit_log', conn, if_exists='append', index=False)
    conn.close()
    print(f"Archived {len(df)} records.")

if __name__ == "__main__":
    if not os.path.exists(OUTPUT_DIR): os.makedirs(OUTPUT_DIR)
    init_db()
    archive_current_run()
