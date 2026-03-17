# META-AUDIT: SYSTEM SELF-ANALYSIS
# Determines which methodological pillars are driving model divergence.

suppressPackageStartupMessages({
  library(data.table)
  library(stats)
})

# Load Data
dt <- fread("output/master_unified_intelligence.csv")

cat("\n--- META-INTELLIGENCE REPORT ---\n")

# 1. CORRELATION MATRIX
# Do our metrics correlate? (e.g. Is low integrity correlated with high decay?)
cols <- c("inf_frac", "fpi_score", "cte_penalty", "divergence_pct", "uds_score")
# Handle NAs
dt_clean <- na.omit(dt[, ..cols])
if (nrow(dt_clean) > 5) {
  cor_mat <- cor(dt_clean)
  print(round(cor_mat, 2))
}

# 2. DIVERGENCE PREDICTION
# "What causes models to fail?" (Divergence > 0)
# We model Divergence % as a function of Integrity and Stability
if (nrow(dt_clean) > 10) {
  cat("\n[Regression] Predicting Model Divergence (Failure):\n")
  # We use log(divergence + 1) because errors are usually log-normal
  model <- lm(log(divergence_pct + 1) ~ inf_frac + fpi_score + cte_penalty, data = dt_clean)
  s <- summary(model)
  
  # Print significant coefficients
  coefs <- coef(s)
  print(coefs)
  
  # Interpretation
  sig_drivers <- rownames(coefs)[coefs[,4] < 0.1] # p < 0.1
  if (length(sig_drivers) > 1) { # > 1 because Intercept is usually there
    cat("\n>> INSIGHT: The following factors significantly predict model instability:\n")
    cat(paste(" -", setdiff(sig_drivers, "(Intercept)"), collapse = "\n"))
    cat("\n")
  } else {
    cat("\n>> INSIGHT: Divergence appears random (no single pillar explains failures).\n")
  }
}

# 3. VERDICT DISTRIBUTION
cat("\n[Verdict Distribution]\n")
print(table(dt$hta_verdict))
