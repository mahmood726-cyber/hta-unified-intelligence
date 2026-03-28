Mahmood Ahmad
Tahir Heart Institute
mahmood.ahmad2@nhs.net

HTA Unified Intelligence System: Self-Correcting Evidence Synthesis with Triple-Guard Ensemble Pooling

Can a unified framework synthesize multiple evidence dimensions into a single Health Technology Assessment decision score that accounts for methodological divergence across estimators? We analyzed 44 technologies from the Pairwise70 Cochrane dataset, computing log odds ratios and standardized mean differences from study-level data using five engines covering integrity, stability, transportability, value, and ensemble robustness. The system integrates these engines via weighted scoring into a Unified Decision Score enhanced by Triple-Guard Ensemble Pooling combining grey relational, Winsorized random-effects, and selection-weighted estimators with leave-one-out fragility detection. The mean OR-scale divergence across technologies was 39.9 percent with 95% CI 28 to 52, and the guard rail classified 75 percent as Fragile with mean score of 30.9. Sensitivity analysis across three default-assumption scenarios showed consistent classification for 86 percent of all evaluated technologies. Single-method meta-analysis substantially underestimates overall evidence fragility in HTA decision-making contexts. The limitation is that conservative defaults for missing pillar data may systematically bias composite scores downward.

Outside Notes

Type: methods
Primary estimand: Unified Decision Score (UDS, 0-100)
App: HTA Unified Intelligence System v1.0
Data: 44 technologies from Pairwise70 Cochrane dataset
Code: https://github.com/mahmood726-cyber/hta-unified-intelligence
Version: 1.0
Validation: DRAFT

References

1. Walsh M, Srinathan SK, McAuley DF, et al. The statistical significance of randomized controlled trial results is frequently fragile: a case for a Fragility Index. J Clin Epidemiol. 2014;67(6):622-628.
2. Atal I, Porcher R, Boutron I, Ravaud P. The statistical significance of meta-analyses is frequently fragile: definition of a fragility index for meta-analyses. J Clin Epidemiol. 2019;111:32-40.
3. Borenstein M, Hedges LV, Higgins JPT, Rothstein HR. Introduction to Meta-Analysis. 2nd ed. Wiley; 2021.

AI Disclosure

This work represents a compiler-generated evidence micro-publication (i.e., a structured, pipeline-based synthesis output). AI is used as a constrained synthesis engine operating on structured inputs and predefined rules, rather than as an autonomous author. Deterministic components of the pipeline, together with versioned, reproducible evidence capsules (TruthCert), are designed to support transparent and auditable outputs. All results and text were reviewed and verified by the author, who takes full responsibility for the content. The workflow operationalises key transparency and reporting principles consistent with CONSORT-AI/SPIRIT-AI, including explicit input specification, predefined schemas, logged human-AI interaction, and reproducible outputs.
