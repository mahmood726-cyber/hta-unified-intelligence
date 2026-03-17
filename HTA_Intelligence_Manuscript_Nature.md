# The HTA Unified Intelligence System: A Self-Correcting Framework for Evidence Synthesis using Triple-Guard Ensemble Pooling

**Authors:** Mahmood Ul Hassan [ORCID_PLACEHOLDER]

**Affiliation:** Independent Researcher, United Kingdom

**Corresponding Author:** Mahmood Ul Hassan ([CORRESPONDING_EMAIL_PLACEHOLDER])

---

### Abstract

**Background:** Health Technology Assessment (HTA) decisions require integration of multiple evidence dimensions—statistical power, publication bias, temporal stability, real-world transportability, and economic value—yet current frameworks evaluate these dimensions in isolation, leading to fragmented and inconsistent recommendations.

**Methods:** We developed the HTA Unified Intelligence System (UIS), a comprehensive framework that synthesizes five methodology engines into a single Unified Decision Score (UDS, 0–100). A key innovation is the Triple-Guard Ensemble Pooling (TGEP), a robustness guard rail that combines three independent meta-analytic estimators (Grey Relational, Winsorized Random-effects, and Selection-Weighted) with Leave-One-Out (LOO) fragility detection. The system features a self-correcting feedback loop that penalizes results with high methodological divergence. We applied the UIS to 44 medical technologies derived from Cochrane systematic reviews in the Pairwise70 dataset, computing effect sizes from raw study-level data using the log odds ratio (binary outcomes) or standardized mean difference (continuous outcomes).

**Results:** No technology achieved "Immutable Truth" status (UDS $\geq$ 70); 5 (11.4%) were classified as Conditional, 33 (75.0%) as Fragile, and 6 (13.6%) as Reject (mean UDS = 30.9, SD = 12.6). The TGEP Guard Rail detected substantial model divergence (>30%) in 24 of 44 technologies (54.5%), with median divergence of 39.9%. The primary fragility driver was high model divergence (54.5%), followed by low statistical power (40.9%). Three technologies (6.8%) were identified as LOO-fragile, where removal of a single study shifted the TGEP ensemble estimate below the clinical relevance threshold ($|\hat{\theta}| \leq 0.05$). Sensitivity analysis across three default-assumption scenarios showed that TGEP penalties shifted 6 technologies from Fragile to Reject compared to the four-pillar baseline without guard rail penalties.

**Conclusion:** The UIS framework reveals that the majority of Cochrane-appraised technologies fail to achieve robust, multi-dimensional evidence quality. The TGEP Guard Rail successfully identified over half of technologies as having unstable estimates across different meta-analytic approaches. These findings suggest that single-method meta-analysis substantially underestimates evidence fragility.

---

### 1. Introduction

Health Technology Assessment (HTA) is the systematic evaluation of medical technologies to inform reimbursement and coverage decisions [1]. Modern HTA relies on meta-analysis as the primary evidence synthesis tool, yet meta-analytic conclusions face multiple threats to their validity: publication bias, insufficient information size, poor generalizability to real-world populations, and sensitivity to individual study contributions [2].

Current HTA frameworks address these concerns through qualitative checklists (e.g., GRADE) that evaluate each dimension separately [3]. This siloed approach can produce contradictory signals—a meta-analysis may show statistically significant benefits while simultaneously being underpowered, biased, and poorly transportable to the target population.

We introduce the HTA Unified Intelligence System (UIS), which integrates five quantitative engines into a single, transparent decision score enhanced by a novel Triple-Guard Ensemble Pooling (TGEP) mechanism that serves as an independent robustness check. Unlike existing HTA frameworks that rely on subjective domain ratings, the UIS produces a continuous, reproducible composite score with explicit configuration transparency.

---

### 2. Materials and Methods

#### 2.1 Data Source

We analyzed 44 medical technologies from the Pairwise70 dataset, a curated collection of 501 Cochrane systematic reviews with individual study-level data [5]. For each technology, effect sizes and sampling variances were computed from raw study data using the `escalc()` function in the metafor R package [6]: log odds ratios for binary outcomes (with 0.5 continuity correction for zero cells) and Hedges' g standardized mean differences for continuous outcomes. Where pre-computed generic inverse variance (GIV) estimates were available with non-zero standard errors, these were used directly. The 44 technologies represent those with complete upstream data from all five pillar engines.

#### 2.2 System Architecture

The UIS integrates five pillar engines, each addressing a distinct dimension of evidence quality:

**Table 1: UIS Pillar Architecture**

| Pillar | Engine | Weight | Input |
|:-------|:-------|:------:|:------|
| Integrity | OIS/Bias Detection | 30% | Information Fraction, Trim-and-Fill, PET-PEESE |
| Stability | Adaptive Stability Engine | 25% | Future-Proof Index, evidence decay prediction |
| Transportability | Clinical Transport Engine | 25% | CTE penalty from ClinicalTrials.gov population matching |
| Value | Net Clinical Benefit | 20% | Harm-benefit ratio, economic threshold |
| Guard Rail | TGEP | Penalty | Ensemble divergence, LOO fragility |

#### 2.3 The Unified Decision Score (UDS)

The UDS is computed as a weighted sum of normalized pillar scores:

$$UDS = \sum_{p \in \{I, S, T, V\}} w_p \cdot S_p - D_{penalty}$$

where $S_p$ is the pillar-specific score (0–100 scale), $w_p$ are the configurable weights (Table 1), and $D_{penalty}$ is the divergence penalty from the TGEP Guard Rail (maximum 10 points).

Missing engine data is handled gracefully: each pillar uses a conservative default (e.g., CTE penalty defaults to 0.70, stability defaults to 50/100) when upstream data is unavailable. The DCI is computed as a weight-adjusted completeness score: $DCI = \sum_p w_p \cdot \mathbb{1}[\text{real data}_p] \times 100$, where $w_p$ are the pillar weights (Table 1). The mean DCI in this analysis was 58.4%, reflecting that the Integrity (30%) and Transportability (25%) pillars had real data for all 44 technologies, while the Stability pillar had real data for only 1 technology (2.3%) and the Value pillar for 5 (11.4%). The remaining Stability and Value scores used conservative defaults, making the effective UDS primarily driven by the Integrity, Transportability, and TGEP pillars.

#### 2.4 Triple-Guard Ensemble Pooling (TGEP)

The TGEP combines three independent meta-analytic estimators:

1. **GRMA Guard Core:** Grey Relational Meta-Analysis using precision-weighted grey relational coefficients with robust 5th–95th percentile scaling [7].
2. **WRD Guard Core:** Winsorized Random-effects with REML estimation and outlier Winsorization at $\pm 2.5$ standard deviations.
3. **SWA Guard Core:** Selection-Weighted Analysis that upweights non-significant studies (p $\geq$ 0.05) by a factor of 2.5 relative to significant studies, serving as a publication bias sensitivity check. If the pooled estimate changes substantially when underrepresented non-significant studies receive greater weight, this indicates selection-dependent instability [9].

Guard weights are determined by LOO cross-validation performance with softmax temperature scaling:

$$w_g = \frac{\exp(-\tilde{e}_g / T)}{\sum_{g'} \exp(-\tilde{e}_{g'} / T)}, \quad \tilde{e}_g = \frac{\bar{e}_g - \min_g \bar{e}_g}{\max_g \bar{e}_g - \min_g \bar{e}_g}$$

where $\bar{e}_g$ is the mean LOO prediction error (squared error divided by variance) for guard $g$, $\tilde{e}_g$ is the min-max normalized error, and $T$ is the temperature parameter (default: 1.0) controlling weight sparsity. Normalization ensures the softmax operates on the [0, 1] scale regardless of error magnitude. For computational efficiency, LOO weight estimation uses fixed-effect models when $k > 15$ studies, while the final guard estimates always use REML.

#### 2.5 Divergence Penalty

To prevent artificial score inflation for small effect sizes, we implemented a Hybrid Divergence calculation:
- For $|\hat{\theta}| < 0.1$: $D = |\hat{\theta}_{TGEP} - \hat{\theta}_{orig}| \times 100$ (absolute divergence)
- For $|\hat{\theta}| \geq 0.1$: $D = |\hat{\theta}_{TGEP} - \hat{\theta}_{orig}| / |\hat{\theta}_{orig}| \times 100$ (relative divergence)

When divergence exceeds the configurable trigger (default: 20%), the UDS is penalized by $\min(D_{max}, (D - D_{trigger})/2)$ points, where $D_{max} = 10$.

#### 2.6 Verdict Classification

Technologies are classified into four tiers based on UDS:

| Verdict | Threshold | Interpretation |
|:--------|:---------:|:---------------|
| IMMUTABLE TRUTH | $\geq$ 70 | Robust across all dimensions; approve |
| CONDITIONAL | $\geq$ 40 | Further evidence recommended |
| FRAGILE | $\geq$ 20 | Multiple quality concerns; conditional with monitoring |
| REJECT | $<$ 20 | Insufficient evidence; do not fund |

#### 2.7 LOO Fragility Detection

For technologies with 4–20 studies, the TGEP performs a LOO fragility analysis: the full ensemble estimate is computed, then re-computed with each study removed in turn. If the full estimate exceeds the clinical relevance threshold ($|\hat{\theta}_{TGEP}| > 0.05$) but any LOO estimate falls below it ($|\hat{\theta}_{TGEP,-i}| \leq 0.05$), the technology is flagged as LOO-fragile and receives an additional UDS penalty of 15 points. Note that this threshold is applied to the point estimate on the effect-size scale, not to statistical significance (p-value).

#### 2.8 Configuration Transparency

All thresholds, weights, and parameters are centralized in a single Configuration Engine (`config.R`), ensuring full transparency and reproducibility. No parameters are hardcoded in analysis scripts. All critical values use `qnorm()` rather than hardcoded constants.

#### 2.9 Software and Reproducibility

All analyses were conducted in R 4.5.2 using metafor (version 4.6), data.table, and dplyr. The complete pipeline is available in the project repository. The analysis was run serially (one technology at a time) for deterministic reproducibility.

---

### 3. Results

#### 3.1 The Tiered Truth Landscape

Our analysis of 44 Cochrane-level technologies from the Pairwise70 dataset revealed that none achieved "Immutable Truth" status (Figure 1). The mean UDS was 30.9 (SD = 12.6, 95% CI: 27.1–34.7, range: 2.6–64.0, median: 31.0).

**Table 2: Distribution of HTA Verdicts**

| Verdict | n | % |
|:--------|--:|--:|
| IMMUTABLE TRUTH | 0 | 0.0 |
| CONDITIONAL | 5 | 11.4 |
| FRAGILE | 33 | 75.0 |
| REJECT | 6 | 13.6 |

The majority of technologies (75.0%) resided in the Fragile tier, indicating that while they may show statistically significant effects in standard meta-analysis, their evidence base is insufficient, biased, or poorly transportable when evaluated across all five dimensions simultaneously.

#### 3.2 Guard Rail Discovery

The TGEP Guard Rail detected substantial divergence between standard meta-analytic estimates and the ensemble estimate. Model divergence exceeded 30% in 24 of 44 technologies (54.5%, 95% CI: 39.8–68.4%). Across all 44 technologies, mean divergence was 92.9% (median: 39.9%); among the 24 high-divergence technologies specifically, mean divergence was substantially higher. In high-divergence cases, the three independent guard cores produced substantially different pooled estimates, indicating fundamental instability in the underlying evidence base.

Of the 44 technologies, 38 (86.4%) received a "Confirmed" TGEP status (the ensemble agreed on a non-null effect), 4 (9.1%) were "Inconclusive" (near-null with wide confidence intervals), and 2 (4.5%) were "Precise Null" (near-zero effect with narrow intervals).

#### 3.3 LOO Fragility

Three technologies (6.8%) were identified as LOO-fragile: removal of a single study from the meta-analysis caused the TGEP ensemble point estimate to drop below the clinical relevance threshold ($|\hat{\theta}| \leq 0.05$), despite the full-data estimate exceeding it. These technologies received the 15-point LOO penalty, contributing to their classification as Reject or Fragile.

#### 3.4 Fragility Reasons

For technologies not reaching Immutable Truth, the primary fragility driver was high model divergence (n = 24, 54.5%), indicating that the TGEP ensemble produced substantially different estimates from the standard approach. The second most common reason was low statistical power (n = 18, 40.9%), where the information fraction fell below the optimal information size. Publication bias was the primary driver in 1 technology (2.3%).

**Table 3: Primary Fragility Reasons**

| Reason | n | % |
|:-------|--:|--:|
| High Model Divergence (TGEP > 30%) | 24 | 54.5 |
| Low Power/Integrity | 18 | 40.9 |
| Bias Detected | 1 | 2.3 |
| Multiple Minor Factors | 1 | 2.3 |

#### 3.5 Sensitivity Analysis

UDS scores were computed under three default-assumption scenarios for missing engine data:

To isolate the effect of default assumptions from the TGEP guard rail, the sensitivity analysis was run on the four-pillar UDS (without TGEP divergence or LOO penalties):

**Table 4: Four-Pillar UDS Verdict Distribution Under Default Scenarios (No TGEP Penalties)**

| Scenario | IMMUTABLE | CONDITIONAL | FRAGILE | REJECT |
|:---------|:---------:|:-----------:|:-------:|:------:|
| Optimistic Defaults | 2 | 33 | 9 | 0 |
| Neutral Defaults | 0 | 9 | 35 | 0 |
| Pessimistic Defaults | 0 | 5 | 37 | 2 |

Comparing Table 4 (Neutral, no TGEP) with Table 2 (full pipeline with TGEP) reveals the impact of the guard rail: of the 9 technologies classified as Conditional without TGEP, 4 were downgraded to Fragile or Reject after applying divergence and LOO penalties; similarly, 6 technologies that were Fragile without TGEP moved to Reject. Under optimistic assumptions (where all missing engines receive favorable defaults), 2 technologies achieved Immutable Truth status even without TGEP penalties, while pessimistic assumptions pushed 2 into Reject.

---

### 4. Discussion

#### 4.1 From Static Appraisal to Dynamic Intelligence

The UIS framework represents a paradigm shift from static, dimension-by-dimension HTA appraisal to integrated, self-correcting decision support. The finding that zero technologies achieved Immutable Truth status—even among Cochrane-appraised interventions—is sobering but methodologically informative. It reflects the compounding effect of evaluating multiple quality dimensions simultaneously: a technology that appears adequate on any single dimension may still fall short when integrity, stability, transportability, value, and robustness are all required.

#### 4.2 The Value of Divergence Detection

The discovery that 54.5% of technologies showed model divergence exceeding 30% has important implications for HTA practice. In these cases, three valid but different meta-analytic approaches (grey relational, winsorized random-effects, and selection-weighted) produced substantially different pooled estimates. Standard practice of relying on a single random-effects model would miss this instability entirely. The high prevalence of divergence suggests that methodological sensitivity analysis should be a mandatory component of HTA submissions.

#### 4.3 Integration Design

The modular architecture allows the UIS to operate with partial data (mean DCI: 58.4%). When an upstream engine is unavailable, the system uses conservative defaults and reports the DCI. This design ensures the framework degrades gracefully rather than failing entirely—a practical necessity for real-world HTA agencies that may not have access to all five engines for every technology.

#### 4.4 Limitations

1. **Sample size:** Analysis of 44 technologies limits generalizability. Extension to the full 501 reviews in the Pairwise70 dataset is planned, requiring automation of the upstream evidence integrity and transportability pipelines for all reviews.
2. **TGEP assumptions:** The guard rail assumes study-level outliers should be downweighted via Winsorization; in rare diseases with few studies, high-leverage studies may represent true signal rather than noise.
3. **Weight selection:** UDS pillar weights (30/25/25/20) are based on methodological reasoning about relative importance but should be validated against longitudinal outcomes (e.g., Cochrane review updates that confirm or reverse original conclusions).
4. **Economic dimension:** The Value engine uses a simplified net clinical benefit calculation rather than full cost-effectiveness modeling with incremental cost-effectiveness ratios.
5. **LOO threshold:** The 0.05 threshold for LOO fragility detection (point estimate crossing zero) is conventional but arbitrary. Alternative thresholds based on clinical significance could be implemented via the configuration engine.
6. **Data completeness:** The mean DCI of 58.4% indicates that approximately 40% of pillar scores relied on conservative defaults rather than real upstream data, which may attenuate the discriminative power of the UDS. In particular, the Stability pillar had real data for only 1 of 44 technologies (2.3%), making the current analysis effectively a three-pillar system (Integrity, Transportability, TGEP guard rail) with constant Stability and near-constant Value contributions. Extension of the Meta-Ecosystem Model pipeline to all 44 technologies would strengthen the Stability pillar.
7. **First-analysis selection:** For technologies with multiple analyses per review, only the first analysis was used for TGEP computation, which may not represent the primary outcome.

---

### 5. Conclusion

The HTA Unified Intelligence System, powered by the TGEP Guard Rail and centralized configuration, reveals that the vast majority of Cochrane-appraised medical technologies (75.0%) are classified as Fragile when evaluated across multiple evidence dimensions simultaneously. The TGEP Guard Rail identified over half (54.5%) of technologies as having unstable estimates across different meta-analytic approaches—a finding that would be invisible to single-method analysis. These results argue for mandatory multi-method sensitivity analysis in HTA submissions and for the adoption of composite evidence quality scores that integrate statistical power, bias, stability, transportability, and robustness into a single transparent metric.

---

### Data Availability Statement

All analysis scripts, configuration files, and generated outputs are available in the project repository at [REPOSITORY_URL_PLACEHOLDER]. The Pairwise70 source data is derived from publicly available Cochrane systematic reviews [5].

### Ethics Statement

This study exclusively used aggregate published data from Cochrane systematic reviews. No individual participant data were accessed and no human participants were involved. Ethics approval was not required.

### Author Contributions (CRediT)

**Mahmood Ul Hassan (MUH):** Conceptualization, Methodology, Software, Validation, Formal Analysis, Investigation, Data Curation, Writing – Original Draft, Writing – Review & Editing, Visualization, Project Administration.

### Funding

The author received no specific funding for this work.

### Competing Interests

The author declares no competing interests.

---

### References

1. Drummond MF, Sculpher MJ, Claxton K, Stoddart GL, Torrance GW. Methods for the Economic Evaluation of Health Care Programmes. 4th ed. Oxford University Press; 2015. https://doi.org/10.1093/oso/9780198529446.001.0001
2. Ioannidis JPA. Why most published research findings are false. PLoS Med. 2005;2(8):e124. https://doi.org/10.1371/journal.pmed.0020124
3. Guyatt GH, Oxman AD, Vist GE, et al. GRADE: an emerging consensus on rating quality of evidence and strength of recommendations. BMJ. 2008;336(7650):924-926. https://doi.org/10.1136/bmj.39489.470347.AD
4. Deng JL. Introduction to Grey System Theory. J Grey Syst. 1989;1(1):1-24.
5. Cochrane Collaboration. Cochrane Database of Systematic Reviews. https://www.cochranelibrary.com/
6. Viechtbauer W. Conducting meta-analyses in R with the metafor package. J Stat Softw. 2010;36(3):1-48. https://doi.org/10.18637/jss.v036.i03
7. Hassan MU. Grey Relational Meta-Analysis: A novel approach to robust effect estimation. [Manuscript in preparation]. 2026.
8. Higgins JPT, Thomas J, Chandler J, et al. Cochrane Handbook for Systematic Reviews of Interventions. Version 6.4. Cochrane; 2023. https://doi.org/10.1002/9781119536604
9. Copas JB, Shi JQ. A sensitivity analysis for publication bias in systematic reviews. Stat Methods Med Res. 2001;10(4):251-265. https://doi.org/10.1177/096228020101000402
10. Stanley TD, Doucouliagos H. Meta-regression approximations to reduce publication selection bias. Res Synth Methods. 2014;5(1):60-78. https://doi.org/10.1002/jrsm.1095
11. Duval S, Tweedie R. Trim and fill: A simple funnel-plot-based method of testing and adjusting for publication bias in meta-analysis. Biometrics. 2000;56(2):455-463. https://doi.org/10.1111/j.0006-341X.2000.00455.x
12. Brok J, Thorlund K, Gluud C, Wetterslev J. Trial sequential analysis reveals insufficient information size and potentially false positive results in many meta-analyses. J Clin Epidemiol. 2008;61(8):763-769. https://doi.org/10.1016/j.jclinepi.2007.10.007
13. Hastie T, Tibshirani R, Friedman J. The Elements of Statistical Learning. 2nd ed. Springer; 2009. https://doi.org/10.1007/978-0-387-84858-7
14. Huber PJ. Robust Statistics. John Wiley & Sons; 1981. https://doi.org/10.1002/0471725250
