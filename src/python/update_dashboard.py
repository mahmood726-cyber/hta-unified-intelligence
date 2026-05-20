# -*- coding: utf-8 -*-
import pandas as pd
import json
import os
from bs4 import BeautifulSoup

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.join(SCRIPT_DIR, "..", "..")
OUTPUT_DIR = os.path.join(PROJECT_ROOT, "output")
CSV_PATH = os.path.join(OUTPUT_DIR, "master_unified_intelligence.csv")
HTML_PATH = os.path.join(PROJECT_ROOT, "Unified_HTA_Dashboard.html")
NARRATIVE_PATH = os.path.join(OUTPUT_DIR, "narratives.json")

STRINGS = {"disclaimer": "\u26A0\uFE0F AI ETHICS DISCLAIMER: Automated Decision Support System."}
ICONS = {'Confirmed': '\u2705', 'No Effect': '\u26A1', 'Precise Null': '\u26D4', 'Inconclusive': '\u2753', 'Data Error': '\u26A0'}

def load_data():
    return pd.read_csv(CSV_PATH).sort_values(by="uds_score", ascending=False)

def load_narratives():
    if os.path.exists(NARRATIVE_PATH):
        with open(NARRATIVE_PATH, 'r') as f: return json.load(f)
    return {}

def generate_table_row(soup, row, narratives):
    tr = soup.new_tag('tr'); tr['class'] = 'hover-row'
    v_class = {"IMMUTABLE TRUTH": "bg-truth", "CONDITIONAL": "bg-conditional", "FRAGILE": "bg-fragile", "REJECT": "bg-reject"}.get(row['hta_verdict'], "bg-fragile")
    
    td_exp = soup.new_tag('td', **{'class': 'dt-control', 'style': 'cursor:pointer; text-align:center;'}); td_exp.string = "+"; tr.append(td_exp)
    td_key = soup.new_tag('td'); td_key.string = str(row['key']); tr.append(td_key)

    td_dci = soup.new_tag('td'); dci = row.get('dci_score', 0); td_dci.string = f"{dci:.0f}%"
    if dci < 25: td_dci['style'] = "color: #e74c3c; font-weight: bold;"
    tr.append(td_dci)

    for val in [f"{row['inf_frac']:.2f}", f"{row['cte_penalty']*100:.1f}%", f"{row['ncb_raw']:.2f}" if not pd.isna(row.get('ncb_raw')) else "N/A"]:
        td = soup.new_tag('td'); td.string = val; tr.append(td)

    td_uds = soup.new_tag('td'); td_uds.string = f"{row['uds_score']:.1f}"; tr.append(td_uds)

    td_guard = soup.new_tag('td')
    st = str(row.get('tgep_status', 'N/A'))
    col = {'Confirmed': '#27ae60', 'No Effect': '#f39c12', 'Precise Null': '#2ecc71', 'Inconclusive': '#9b59b6'}.get(st, '#7f8c8d')
    span = soup.new_tag('span', style=f'color:{col}; font-weight:bold')
    span.string = f"{ICONS.get(st, '')} {st}"; td_guard.append(span); tr.append(td_guard)

    td_act = soup.new_tag('td'); span_act = soup.new_tag('span', style="font-size:0.8em; color:#94a3b8")
    raw_act = str(row.get('recommended_action', 'N/A'))
    if "Reject" in raw_act: raw_act = "Review for Rejection"
    span_act.string = raw_act; td_act.append(span_act); tr.append(td_act)

    td_ver = soup.new_tag('td'); sp = soup.new_tag('span', **{'class': f'badge {v_class}'}); sp.string = row['hta_verdict']; td_ver.append(sp); tr.append(td_ver)

    brief = narratives.get(row['key'], "No briefing available.")
    v_folder = row['hta_verdict'].replace(" ", "_")
    plot = f"output/plots/{v_folder}/forest_{row['key']}.png"
    tr['data-brief'] = brief; tr['data-plot'] = plot
    return tr

def update_html(df):
    narratives = load_narratives()
    try:
        with open(HTML_PATH, 'r', encoding='utf-8') as f: soup = BeautifulSoup(f, 'html.parser')
    except: soup = BeautifulSoup("<html><body></body></html>", 'html.parser')

    if not soup.body: soup.append(soup.new_tag('body'))
    if not soup.head: soup.insert(0, soup.new_tag('head'))

    # Ticker (CSS-animated; <marquee> is deprecated)
    if soup.find('div', id='news-ticker'): soup.find('div', id='news-ticker').decompose()
    ticker = soup.new_tag('div', id='news-ticker', style="background:#0f172a; color:#38bdf8; padding:10px; font-family:monospace; border-bottom:1px solid #334155; white-space:nowrap; overflow:hidden;")
    track = soup.new_tag('div', **{'class': 'ticker-track', 'style': 'display:inline-block; padding-left:100%; animation: ticker-scroll 40s linear infinite;'})
    ticker_text = "SYSTEM STATUS: ONLINE | LATEST INSIGHTS: "
    for _, row in df.head(5).iterrows(): ticker_text += f" - {row['key']}: {row['hta_verdict']} "
    track.string = ticker_text
    ticker.append(track)
    style_tag = soup.new_tag('style')
    style_tag.string = "@keyframes ticker-scroll { from { transform: translateX(0); } to { transform: translateX(-100%); } }"
    ticker.append(style_tag)
    soup.body.insert(0, ticker)

    # Assets
    asset_path = os.path.join(OUTPUT_DIR, "assets", "jquery.min.js")
    if os.path.exists(asset_path):
        for script in soup.find_all('script'):
            src = script.get('src', '')
            if 'jquery' in src: script['src'] = 'output/assets/jquery.min.js'

    tbody = soup.find('tbody')
    if not tbody:
        if not soup.find('table'): 
            table = soup.new_tag('table'); soup.body.append(table)
        else: table = soup.find('table')
        tbody = soup.new_tag('tbody'); table.append(tbody)
    
    tbody.clear()
    for _, row in df.iterrows(): tbody.append(generate_table_row(soup, row, narratives))

    script = soup.find('script', string=lambda t: t and "$('table').DataTable" in t)
    if not script: script = soup.new_tag('script'); soup.body.append(script)
    script.string = r"""
    function format(d) {
        var row = $(d).closest('tr');
        var brief = row.attr('data-brief');
        var plot = row.attr('data-plot');
        return '<div style="padding:20px; background:#1e293b; border-radius:8px; display:flex;">' +
               '<div style="flex:1; padding-right:20px;"><h4>Briefing</h4><p>' + brief + '</p></div>' +
               '<div style="flex:1;"><a href="' + plot + '" target="_blank"><img src="' + plot + '" style="width:100%; border-radius:4px;"></a></div>' +
               '</div>';
    }
    $(document).ready(function() {
        var table = $('table').DataTable({ dom: 'Bfrtip', buttons: ['copy', 'csv', 'excel', 'pdf'], pageLength: 25, order: [[9, 'asc'], [6, 'desc']], rowGroup: { dataSrc: 9 } });
        $('table tbody').on('click', 'td.dt-control', function () {
            var tr = $(this).closest('tr');
            var row = table.row(tr);
            if (row.child.isShown()) { row.child.hide(); tr.removeClass('shown'); $(this).text('+'); }
            else { row.child(format(tr)).show(); tr.addClass('shown'); $(this).text('-'); }
        });
    });
    """

    if "AI ETHICS DISCLAIMER" not in str(soup):
        footer = soup.new_tag('div', style="margin-top: 50px; border-top: 1px solid #334155; padding-top: 20px; color: #64748b; font-size: 0.8em; text-align: center;")
        footer.string = STRINGS["disclaimer"]
        soup.body.append(footer)

    with open(HTML_PATH, 'w', encoding='utf-8') as f: f.write(str(soup))

if __name__ == "__main__":
    df = load_data(); update_html(df)
    print("Dashboard updated.")
