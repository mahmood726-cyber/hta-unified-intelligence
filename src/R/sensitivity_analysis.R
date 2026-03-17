#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(data.table)
  library(dplyr)
  library(ggplot2)
})

# Set working directory to script location
args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("--file=", "", args[grep("--file=", args)])
if(length(script_path) > 0) {
  setwd(dirname(script_path))
}

cat(sprintf("Working Directory: %s\n", getwd()))

base_dir <- ".."
paths <- list(
  integrity = file.path(base_dir, "HTA_Evidence_Integrity_Suite/analysis/output/unified_hta_validation.csv"),
  decay     = file.path(base_dir, "Meta_Ecosystem_Model/output/future_proof_atlas.csv"),
  transport = file.path(base_dir, "HTA_Transportability_Engine/output/transportability_results.csv"),
  value     = file.path(base_dir, "Value_Based_HTA_Engine/output/net_clinical_benefit.csv")
)

safe_fread <- function(path) {
  if (file.exists(path)) {
    dt <- fread(path)
    if (nrow(dt) > 0) return(dt)
  }
  cat(sprintf("Warning: File not found: %s\n", path))
  return(NULL)
}

dt_integrity <- safe_fread(paths$integrity)
dt_decay     <- safe_fread(paths$decay)
dt_transport <- safe_fread(paths$transport)
dt_value     <- safe_fread(paths$value)

# Assign keys and aggregate
if(!is.null(dt_integrity)) {
    dt_integrity[, review_key := dataset_name]
    agg_integrity <- dt_integrity[, .(inf_frac = mean(inf_frac, na.rm = TRUE)), by = "review_key"]
} else {
    agg_integrity <- data.table(review_key=character(), inf_frac=numeric())
}

if(!is.null(dt_decay)) {
    dt_decay[, review_key := dataset_name]
    agg_decay <- dt_decay[, .(fpi_score = mean(fpi_score, na.rm = TRUE)), by = "review_key"]
} else {
    agg_decay <- data.table(review_key=character(), fpi_score=numeric())
}

if(!is.null(dt_transport)) {
    dt_transport[, review_key := dataset]
    agg_transport <- dt_transport[, .(cte_penalty = mean(cte_penalty, na.rm = TRUE)), by = "review_key"]
} else {
    agg_transport <- data.table(review_key=character(), cte_penalty=numeric())
}

if(!is.null(dt_value)) {
    dt_value[, review_key := dataset_name]
    agg_value <- dt_value[, .(ncb_raw = mean(ncb_raw, na.rm = TRUE)), by = "review_key"]
} else {
    agg_value <- data.table(review_key=character(), ncb_raw=numeric())
}

cat("Merging...\n")
master_dt <- merge(agg_integrity, agg_decay, by = "review_key", all.x = TRUE)
master_dt <- merge(master_dt, agg_transport, by = "review_key", all.x = TRUE)
master_dt <- merge(master_dt, agg_value, by = "review_key", all.x = TRUE)

cat(sprintf("Merged data has %d rows.\n", nrow(master_dt)))

# Calc Function
calc_scores <- function(df, default_fpi, default_cte) {
  df_copy <- copy(df)
  df_copy[, uds_score := (
    (fcoalesce(pmin(1.5, inf_frac), 0.75)/1.5 * 30) +
    (fcoalesce(fpi_score, default_fpi)/100 * 25) +
    (fcoalesce(cte_penalty, default_cte) * 25) +
    (ifelse(!is.na(ncb_raw) & ncb_raw > 0, 20, 0))
  )]
  
  df_copy[, hta_verdict := case_when(
    uds_score >= 70 ~ "IMMUTABLE TRUTH",
    uds_score >= 40 ~ "CONDITIONAL",
    uds_score >= 20 ~ "FRAGILE",
    TRUE ~ "REJECT"
  )]
  return(df_copy)
}

s1 <- calc_scores(master_dt, default_fpi = 80, default_cte = 0.9)[, .N, by = hta_verdict][, Scenario := "Optimistic Defaults"]
s2 <- calc_scores(master_dt, default_fpi = 50, default_cte = 0.7)[, .N, by = hta_verdict][, Scenario := "Neutral Defaults (Baseline)"]
s3 <- calc_scores(master_dt, default_fpi = 20, default_cte = 0.5)[, .N, by = hta_verdict][, Scenario := "Pessimistic Defaults"]

results <- rbind(s1, s2, s3)
results[, hta_verdict := factor(hta_verdict, levels = c("IMMUTABLE TRUTH", "CONDITIONAL", "FRAGILE", "REJECT"))]

p <- ggplot(results, aes(x = Scenario, y = N, fill = hta_verdict)) +
  geom_bar(stat = "identity", position = "stack") +
  geom_text(aes(label = N), position = position_stack(vjust = 0.5), color = "white", size = 3) +
  scale_fill_manual(values = c("IMMUTABLE TRUTH" = "#27ae60", "CONDITIONAL" = "#2980b9", "FRAGILE" = "#f39c12", "REJECT" = "#c0392b")) +
  theme_minimal() +
  labs(title = "Figure 2: Sensitivity Analysis", y = "Count", x = "")

if (!dir.exists("output")) dir.create("output", showWarnings = FALSE)
ggsave("output/figure2_sensitivity.png", plot = p, width = 8, height = 6, dpi = 300)
fwrite(results, "output/sensitivity_analysis_results.csv")
cat("Sensitivity Analysis Done.\n")
