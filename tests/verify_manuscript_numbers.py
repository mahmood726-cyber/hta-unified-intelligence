"""Verify all numerical claims in the UIS manuscript against pipeline output."""
import csv, sys, os

os.chdir(os.path.join(os.path.dirname(__file__), ".."))

checks = []
def check(name, expected, actual, tol=0.1):
    passed = abs(expected - actual) <= tol
    checks.append((name, passed, expected, actual))
    return passed

# Load master results
with open("output/master_unified_intelligence.csv") as f:
    master = list(csv.DictReader(f))

# Load TGEP results
with open("output/tgep_results.csv") as f:
    tgep = list(csv.DictReader(f))

n = len(master)
check("Total technologies", 44, n)

# Verdict counts
verdicts = {}
for r in master:
    v = r["hta_verdict"]
    verdicts[v] = verdicts.get(v, 0) + 1

check("IMMUTABLE count", 0, verdicts.get("IMMUTABLE TRUTH", 0))
check("CONDITIONAL count", 5, verdicts.get("CONDITIONAL", 0))
check("FRAGILE count", 33, verdicts.get("FRAGILE", 0))
check("REJECT count", 6, verdicts.get("REJECT", 0))

# Percentages
check("CONDITIONAL %", 11.4, 100 * verdicts.get("CONDITIONAL", 0) / n, tol=0.2)
check("FRAGILE %", 75.0, 100 * verdicts.get("FRAGILE", 0) / n, tol=0.2)
check("REJECT %", 13.6, 100 * verdicts.get("REJECT", 0) / n, tol=0.2)

# UDS stats
uds = [float(r["uds_score"]) for r in master]
import statistics
check("UDS mean", 30.9, statistics.mean(uds), tol=0.2)
check("UDS SD", 12.6, statistics.stdev(uds), tol=0.2)
check("UDS min", 2.6, min(uds), tol=0.2)
check("UDS max", 64.0, max(uds), tol=0.2)
check("UDS median", 31.0, statistics.median(uds), tol=0.5)

# Divergence
divs = [float(r["divergence_pct"]) for r in master]
high_div30 = sum(1 for d in divs if d > 30)
check("Divergence >30% count", 24, high_div30)
check("Divergence >30% pct", 54.5, 100 * high_div30 / n, tol=0.2)
check("Mean divergence", 92.9, statistics.mean(divs), tol=0.5)
check("Median divergence", 39.9, statistics.median(divs), tol=0.5)

# TGEP statuses
tgep_statuses = {}
for r in tgep:
    s = r["tgep_status"]
    tgep_statuses[s] = tgep_statuses.get(s, 0) + 1
check("TGEP Confirmed", 38, tgep_statuses.get("Confirmed", 0))
check("TGEP Inconclusive", 4, tgep_statuses.get("Inconclusive", 0))
check("TGEP Precise Null", 2, tgep_statuses.get("Precise Null", 0))

# LOO fragile
loo_fragile = sum(1 for r in tgep if r.get("loo_fragile", "").lower() == "true")
check("LOO fragile count", 3, loo_fragile)
check("LOO fragile %", 6.8, 100 * loo_fragile / len(tgep), tol=0.2)

# Fragility reasons
reasons = {}
for r in master:
    fr = r["fragility_reason"]
    reasons[fr] = reasons.get(fr, 0) + 1
check("High Model Divergence", 24, reasons.get("High Model Divergence", 0))
check("Low Power/Integrity", 18, reasons.get("Low Power/Integrity", 0))
check("Bias Detected", 1, reasons.get("Bias Detected", 0))
check("Multiple Minor Factors", 1, reasons.get("Multiple Minor Factors", 0))

# DCI
dci = [float(r["dci_score"]) for r in master]
check("DCI mean", 58.4, statistics.mean(dci), tol=0.2)

# Summary
passed = sum(1 for _, p, _, _ in checks if p)
failed = sum(1 for _, p, _, _ in checks if not p)

print("=" * 70)
for name, p, exp, act in checks:
    status = "PASS" if p else "FAIL"
    print(f"  [{status}] {name}: expected={exp}, actual={act}")
print("=" * 70)
print(f"SUMMARY: {passed}/{len(checks)} PASS, {failed}/{len(checks)} FAIL")
if failed > 0:
    print("FAILURES DETECTED")
    sys.exit(1)
else:
    print("ALL MANUSCRIPT NUMBERS VERIFIED SUCCESSFULLY")
