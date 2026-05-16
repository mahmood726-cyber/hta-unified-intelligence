# E156 Protocol — `hta-unified-intelligence`

This repository is the source code and dashboard backing an E156 micro-paper on the [E156 Student Board](https://mahmood726-cyber.github.io/e156/students.html).

---

## `[69]` HTA Unified Intelligence System: Self-Correcting Evidence Synthesis with Triple-Guard Ensemble Pooling

**Type:** methods  |  ESTIMAND: Unified Decision Score (UDS, 0-100)  
**Data:** 44 technologies from Pairwise70 Cochrane dataset

### 156-word body

Can a unified framework synthesize multiple evidence dimensions into a single Health Technology Assessment decision score that accounts for methodological divergence across estimators? We analyzed 44 technologies from the Pairwise70 Cochrane dataset, computing log odds ratios and standardized mean differences from study-level data using five engines covering integrity, stability, transportability, value, and ensemble robustness. The system integrates these engines via weighted scoring into a Unified Decision Score enhanced by Triple-Guard Ensemble Pooling combining grey relational, Winsorized random-effects, and selection-weighted estimators with leave-one-out fragility detection. The mean OR-scale divergence across technologies was 39.9 percent with 95% CI 28 to 52, and the guard rail classified 75 percent as Fragile with mean score of 30.9. Sensitivity analysis across three default-assumption scenarios showed consistent classification for 86 percent of all evaluated technologies. Single-method meta-analysis substantially underestimates overall evidence fragility in HTA decision-making contexts. The limitation is that conservative defaults for missing pillar data may systematically bias composite scores downward.

### Submission metadata

```
Corresponding author: Mahmood Ahmad <mahmood.ahmad2@nhs.net>
ORCID: 0000-0001-9107-3704
Affiliation: Tahir Heart Institute, Rabwah, Pakistan

Links:
  Code:      https://github.com/mahmood726-cyber/hta-unified-intelligence
  Protocol:  https://github.com/mahmood726-cyber/hta-unified-intelligence/blob/main/E156-PROTOCOL.md
  Dashboard: https://mahmood726-cyber.github.io/hta-unified-intelligence/

References (topic pack: fragility index):
  1. Walsh M, Srinathan SK, McAuley DF, et al. 2014. The statistical significance of randomized controlled trial results is frequently fragile: a case for a Fragility Index. J Clin Epidemiol. 67(6):622-628. doi:10.1016/j.jclinepi.2013.10.019
  2. Atal I, Porcher R, Boutron I, Ravaud P. 2019. The statistical significance of meta-analyses is frequently fragile: definition of a fragility index for meta-analyses. J Clin Epidemiol. 111:32-40. doi:10.1016/j.jclinepi.2019.03.012

Data availability: No patient-level data used. Analysis derived exclusively
  from publicly available aggregate records. All source identifiers are in
  the protocol document linked above.

Ethics: Not required. Study uses only publicly available aggregate data; no
  human participants; no patient-identifiable information; no individual-
  participant data. No institutional review board approval sought or required
  under standard research-ethics guidelines for secondary methodological
  research on published literature.

Funding: None.

Competing interests: MA serves on the editorial board of Synthēsis (the
  target journal); MA had no role in editorial decisions on this
  manuscript, which was handled by an independent editor of the journal.

Author contributions (CRediT):
  [STUDENT REWRITER, first author] — Writing – original draft, Writing –
    review & editing, Validation.
  [SUPERVISING FACULTY, last/senior author] — Supervision, Validation,
    Writing – review & editing.
  Mahmood Ahmad (middle author, NOT first or last) — Conceptualization,
    Methodology, Software, Data curation, Formal analysis, Resources.

AI disclosure: Computational tooling (including AI-assisted coding via
  Claude Code [Anthropic]) was used to develop analysis scripts and assist
  with data extraction. The final manuscript was human-written, reviewed,
  and approved by the author; the submitted text is not AI-generated. All
  quantitative claims were verified against source data; cross-validation
  was performed where applicable. The author retains full responsibility for
  the final content.

Preprint: Not preprinted.

Reporting checklist: PRISMA 2020 (methods-paper variant — reports on review corpus).

Target journal: ◆ Synthēsis (https://www.synthesis-medicine.org/index.php/journal)
  Section: Methods Note — submit the 156-word E156 body verbatim as the main text.
  The journal caps main text at ≤400 words; E156's 156-word, 7-sentence
  contract sits well inside that ceiling. Do NOT pad to 400 — the
  micro-paper length is the point of the format.

Manuscript license: CC-BY-4.0.
Code license: MIT.

SUBMITTED: [ ]
```


---

_Auto-generated from the workbook by `C:/E156/scripts/create_missing_protocols.py`. If something is wrong, edit `rewrite-workbook.txt` and re-run the script — it will overwrite this file via the GitHub API._