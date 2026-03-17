#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(data.table)
  library(dplyr)
  library(jsonlite)
  library(ggplot2)
})

args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("--file=", "", args[grep("--file=", args)])
if(length(script_path) > 0) setwd(dirname(script_path))

source("../../config.R")

# Detect sibling project root (parent of this project)
project_root <- normalizePath("../../..", winslash = "/", mustWork = FALSE)
models_dir <- Sys.getenv("HTA_MODELS_DIR", unset = project_root)

paths <- list(
  integrity = file.path(models_dir, "HTA_Evidence_Integrity_Suite/analysis/output/unified_hta_validation.csv"),
  decay     = file.path(models_dir, "Meta_Ecosystem_Model/output/future_proof_atlas.csv"),
  transport = file.path(models_dir, "HTA_Transportability_Engine/output/transportability_results.csv"),
  value     = file.path(models_dir, "Value_Based_HTA_Engine/output/net_clinical_benefit.csv"),
  tgep      = "../../output/tgep_results.csv"
)

# Report which engines are available
for (nm in names(paths)) {
  status <- if (file.exists(paths[[nm]])) "FOUND" else "MISSING (will use defaults)"
  cat(sprintf("  Engine %-12s: %s\n", nm, status))
}

out_dir <- "../../output"

safe_fread <- function(path) { if (file.exists(path)) return(fread(path)); return(NULL) }
dt_i <- safe_fread(paths$integrity); dt_d <- safe_fread(paths$decay)
dt_tr <- safe_fread(paths$transport); dt_v <- safe_fread(paths$value)
dt_tg <- safe_fread(paths$tgep)

agg_i <- if(!is.null(dt_i)) dt_i[, .(inf_frac = mean(inf_frac, na.rm = TRUE), bias_detected = any(bias_detected == TRUE), orig_estimate = mean(orig_estimate, na.rm = TRUE)), by = dataset_name] else data.table(dataset_name=character(), inf_frac=numeric(), bias_detected=logical(), orig_estimate=numeric())
agg_d <- if(!is.null(dt_d)) dt_d[, .(fpi_score = mean(fpi_score, na.rm = TRUE)), by = dataset_name] else data.table(dataset_name=character(), fpi_score=numeric())
agg_tr <- if(!is.null(dt_tr)) dt_tr[, .(cte_penalty = mean(cte_penalty, na.rm = TRUE)), by = dataset] else data.table(dataset=character(), cte_penalty=numeric())
agg_v <- if(!is.null(dt_v)) dt_v[, .(ncb_raw = mean(ncb_raw, na.rm = TRUE)), by = dataset_name] else data.table(dataset_name=character(), ncb_raw=numeric())

master_dt <- merge(agg_i, agg_d, by.x = "dataset_name", by.y = "dataset_name", all.x = TRUE)
master_dt <- merge(master_dt, agg_tr, by.x = "dataset_name", by.y = "dataset", all.x = TRUE)
master_dt <- merge(master_dt, agg_v, by.x = "dataset_name", by.y = "dataset_name", all.x = TRUE)
if (!is.null(dt_tg)) master_dt <- merge(master_dt, dt_tg, by.x = "dataset_name", by.y = "tech_key", all.x = TRUE)
setnames(master_dt, "dataset_name", "key")

w <- HTA_CONFIG$weights
calc_uds <- function(dt, weight_value) {
  (fcoalesce(pmin(1.5, dt$inf_frac), 0.75)/1.5 * w$integrity * 100) +
  (fcoalesce(dt$fpi_score, 50)/100 * w$stability * 100) +
  (fcoalesce(dt$cte_penalty, 0.7) * w$transport * 100) +
  (ifelse(!is.na(dt$ncb_raw) & dt$ncb_raw > 0, weight_value * 100, 0))
}
master_dt[, uds_score := calc_uds(master_dt, w$value)]
master_dt[, uds_score_hic := calc_uds(master_dt, w$value * 1.2)]
master_dt[, uds_score_lmic := calc_uds(master_dt, w$value * 0.8)]

master_dt[, dci_score := ((as.numeric(!is.na(inf_frac))*w$integrity) + (as.numeric(!is.na(fpi_score))*w$stability) + (as.numeric(!is.na(cte_penalty))*w$transport) + (as.numeric(!is.na(ncb_raw))*w$value))*100]

master_dt[, divergence_pct := 0]
if ("tgep_est" %in% names(master_dt)) {
  master_dt[, divergence_pct := case_when(
    is.na(tgep_est) | is.na(orig_estimate) ~ 0,
    abs(orig_estimate) < HTA_CONFIG$divergence$small_effect_bound ~ abs(tgep_est - orig_estimate) * 100, 
    TRUE ~ abs(tgep_est - orig_estimate) / (abs(orig_estimate) + 1e-6) * 100 
  )]
  master_dt[divergence_pct > HTA_CONFIG$divergence$penalty_trigger, 
            uds_score := uds_score - pmin(HTA_CONFIG$divergence$max_penalty, (divergence_pct - HTA_CONFIG$divergence$penalty_trigger)/2)]
}

if ("loo_fragile" %in% names(master_dt)) {
  master_dt[loo_fragile == TRUE, uds_score := uds_score - HTA_CONFIG$stability$loo_flip_penalty]
}

master_dt[, hta_verdict := case_when(
  uds_score >= HTA_CONFIG$thresholds$immutable ~ "IMMUTABLE TRUTH",
  uds_score >= HTA_CONFIG$thresholds$conditional ~ "CONDITIONAL",
  uds_score >= HTA_CONFIG$thresholds$fragile ~ "FRAGILE",
  TRUE ~ "REJECT"
)]

# FIXED LOGIC: Vectorized AND (&)
master_dt[, fragility_reason := case_when(
  hta_verdict != "IMMUTABLE TRUTH" & divergence_pct > 30 ~ "High Model Divergence",
  hta_verdict != "IMMUTABLE TRUTH" & bias_detected == TRUE ~ "Bias Detected",
  hta_verdict != "IMMUTABLE TRUTH" & inf_frac < 0.8 ~ "Low Power/Integrity",
  hta_verdict != "IMMUTABLE TRUTH" & fpi_score < 40 ~ "High Evidence Decay",
  hta_verdict != "IMMUTABLE TRUTH" & cte_penalty < 0.6 ~ "Transport Leakage",
  hta_verdict == "IMMUTABLE TRUTH" ~ "N/A (Robust)",
  TRUE ~ "Multiple Minor Factors"
)]

master_dt[, recommended_action := case_when(
  hta_verdict == "IMMUTABLE TRUTH" ~ "Approve for Reimbursement",
  hta_verdict == "REJECT" ~ "Reject (Do Not Fund)",
  fragility_reason == "High Model Divergence" ~ "Request TGEP Audit",
  fragility_reason == "Bias Detected" ~ "Request New Meta-Analysis (Pre-Registered)",
  fragility_reason == "Low Power/Integrity" ~ "New RCT Required",
  fragility_reason == "High Evidence Decay" ~ "Update Systematic Review",
  fragility_reason == "Transport Leakage" ~ "Real-World Evidence Study Required",
  TRUE ~ "Conditional Approval with Monitoring"
)]

master_dt[, last_updated := as.character(Sys.time())]
fwrite(master_dt, file.path(out_dir, "master_unified_intelligence.csv"))
write_json(list(meta=list(timestamp=Sys.time(), version="1.0.0"), data=master_dt), file.path(out_dir, "master_unified_intelligence.json"), pretty=TRUE, auto_unbox=TRUE)
archive_path <- file.path(out_dir, "archive", sprintf("master_audit_%s.csv", format(Sys.time(), "%Y%m%d_%H%M%S")))
fwrite(master_dt, archive_path)

master_dt[, alpha_val := pmax(0.2, 1 - (divergence_pct / 100))]
p <- ggplot(master_dt, aes(x = inf_frac, y = uds_score, color = hta_verdict, alpha = alpha_val)) +
  geom_point(size = 5) + 
  geom_hline(yintercept = c(HTA_CONFIG$thresholds$conditional, HTA_CONFIG$thresholds$immutable), linetype = "dashed", color = "grey50") +
  scale_color_manual(values = c("IMMUTABLE TRUTH" = "#27ae60", "CONDITIONAL" = "#2980b9", "FRAGILE" = "#f39c12", "REJECT" = "#c0392b")) +
  scale_alpha_continuous(name = "Model Confidence", range = c(0.2, 1)) +
  theme_minimal() +
  labs(title = "Figure 1: The Tiered Truth Landscape", subtitle = "Alpha = Model Confidence", x = "Information Fraction", y = "UDS Score") +
  theme(legend.position = "bottom")

ggsave(file.path(out_dir, "figure1_tiered_truth.png"), plot = p, width = 10, height = 7, dpi = 300)
cat("Master Pipeline V15 (Human-Centric) Complete.\n")
