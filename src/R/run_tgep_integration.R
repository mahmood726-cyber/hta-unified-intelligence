#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(data.table)
  library(dplyr)
  library(metafor)
  library(parallel)
})

# Set WD to script dir
args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("--file=", "", args[grep("--file=", args)])
if(length(script_path) > 0) setwd(dirname(script_path))

source("TGEP.R")
source("../../config.R")

cat("HTA UNIFIED INTELLIGENCE SYSTEM: TGEP STABILITY ENGINE\n")

# Portable Pairwise70 path detection
PAIRWISE70_ROOT <- Sys.getenv("PAIRWISE70_ROOT", unset = "")
if (PAIRWISE70_ROOT == "") {
  candidates <- c(
    normalizePath("../../..", winslash = "/", mustWork = FALSE) |> file.path("Pairwise70"),
    normalizePath("C:/Users/user/OneDrive - NHS/Documents/Pairwise70", mustWork = FALSE),
    normalizePath("~/Pairwise70", mustWork = FALSE)
  )
  found <- candidates[dir.exists(candidates)]
  if (length(found) == 0) stop("Pairwise70 not found. Set PAIRWISE70_ROOT env var.")
  PAIRWISE70_ROOT <- found[1]
}
dataset_path <- file.path(PAIRWISE70_ROOT, "data")
input_csv <- "../../output/master_unified_intelligence.csv"
plot_base_dir <- "../../output/plots"

if (!file.exists(input_csv)) stop("Master Intelligence CSV not found.")

dt_master <- fread(input_csv)
technologies <- dt_master$key

run_tgep_stable <- function(tech_id, dataset_path, plot_base_dir, verdict) {
  library(metafor)
  library(data.table)

  rda_file <- file.path(dataset_path, paste0(tech_id, ".rda"))
  if (!file.exists(rda_file)) return(data.table(tech_key = tech_id, tgep_est = NA_real_, tgep_status = "Data Missing", loo_fragile = FALSE))

  e <- new.env(); load(rda_file, envir = e)
  df <- as.data.frame(e[[ls(e)[1]]])

  # Use first analysis only (largest group) to avoid mixing different outcome types
  as_num <- function(x) suppressWarnings(as.numeric(as.character(x)))
  if ("Analysis.number" %in% names(df)) {
    an <- as_num(df[["Analysis.number"]])
    df <- df[!is.na(an) & an == min(an, na.rm = TRUE), , drop = FALSE]
  }

  # Strategy: Try escalc on raw data first, then fall back to pre-computed GIV
  yi_vec <- NULL; vi_vec <- NULL

  # 1. Try binary data (OR via escalc)
  has_binary <- all(c("Experimental.cases", "Experimental.N", "Control.cases", "Control.N") %in% names(df))
  if (has_binary) {
    ec <- as_num(df[["Experimental.cases"]]); en <- as_num(df[["Experimental.N"]])
    cc <- as_num(df[["Control.cases"]]);     cn <- as_num(df[["Control.N"]])
    ok <- is.finite(ec) & is.finite(en) & en > 0 & is.finite(cc) & is.finite(cn) & cn > 0
    if (sum(ok) >= 2) {
      es <- tryCatch(
        escalc(measure = "OR", ai = ec[ok], n1i = en[ok], ci = cc[ok], n2i = cn[ok], add = 0.5, to = "only0"),
        error = function(e) NULL)
      if (!is.null(es) && sum(is.finite(es$yi) & is.finite(es$vi) & es$vi > 0) >= 2) {
        good <- is.finite(es$yi) & is.finite(es$vi) & es$vi > 0
        yi_vec <- as.numeric(es$yi[good]); vi_vec <- as.numeric(es$vi[good])
      }
    }
  }

  # 2. Try continuous data (SMD via escalc)
  if (is.null(yi_vec)) {
    has_cont <- all(c("Experimental.mean", "Experimental.SD", "Experimental.N",
                       "Control.mean", "Control.SD", "Control.N") %in% names(df))
    if (has_cont) {
      em <- as_num(df[["Experimental.mean"]]); es_d <- as_num(df[["Experimental.SD"]]); en <- as_num(df[["Experimental.N"]])
      cm <- as_num(df[["Control.mean"]]);      cs <- as_num(df[["Control.SD"]]);         cn <- as_num(df[["Control.N"]])
      ok <- is.finite(em) & is.finite(es_d) & es_d > 0 & en > 0 & is.finite(cm) & is.finite(cs) & cs > 0 & cn > 0
      if (sum(ok) >= 2) {
        es <- tryCatch(
          escalc(measure = "SMD", m1i = em[ok], sd1i = es_d[ok], n1i = en[ok],
                 m2i = cm[ok], sd2i = cs[ok], n2i = cn[ok]),
          error = function(e) NULL)
        if (!is.null(es) && sum(is.finite(es$yi) & is.finite(es$vi) & es$vi > 0) >= 2) {
          good <- is.finite(es$yi) & is.finite(es$vi) & es$vi > 0
          yi_vec <- as.numeric(es$yi[good]); vi_vec <- as.numeric(es$vi[good])
        }
      }
    }
  }

  # 3. Fall back to pre-computed GIV.Mean/GIV.SE (where both are non-zero)
  if (is.null(yi_vec) && "GIV.Mean" %in% names(df) && "GIV.SE" %in% names(df)) {
    gm <- as_num(df[["GIV.Mean"]]); gs <- as_num(df[["GIV.SE"]])
    ok <- is.finite(gm) & is.finite(gs) & gs > 0 & (gm != 0 | gs != 0)
    if (sum(ok) >= 2) { yi_vec <- gm[ok]; vi_vec <- gs[ok]^2 }
  }

  if (is.null(yi_vec) || length(yi_vec) < 2) {
    return(data.table(tech_key = tech_id, tgep_status = "Insufficient Data"))
  }
  vi <- vi_vec
  
  tryCatch({
    res <- tgep_meta(yi_vec, vi, n_boot = 0)

    loo_fragile <- FALSE
    if (length(yi_vec) > 3 && length(yi_vec) <= 20) {
      loo_results <- tryCatch(
        sapply(seq_along(yi_vec), function(i) abs(tgep_meta(yi_vec[-i], vi[-i], n_boot = 0)$estimate) > 0.05),
        error = function(e) rep(TRUE, length(yi_vec)))
      if (any(loo_results == FALSE) && abs(res$estimate) > 0.05) loo_fragile <- TRUE
    }

    status <- "Confirmed"
    if (abs(res$estimate) < 0.05) status <- ifelse((res$ci_ub - res$ci_lb) < 0.4, "Precise Null", "Inconclusive")

    return(data.table(tech_key = tech_id, tgep_est = res$estimate, tgep_se = res$se,
                      tgep_status = status, loo_fragile = loo_fragile, k_studies = length(yi_vec)))
  }, error = function(e) return(data.table(tech_key = tech_id, tgep_status = paste0("Error: ", conditionMessage(e)))))
}

# Serial for safety
cat(sprintf("Processing %d technologies...\n", length(technologies)))
results_list <- list()
for (i in seq_along(technologies)) {
  results_list[[i]] <- run_tgep_stable(technologies[i], dataset_path, plot_base_dir, dt_master$hta_verdict[i])
  cat(sprintf("  [%d/%d] %s: %s\n", i, length(technologies), technologies[i], results_list[[i]]$tgep_status))
}

results_dt <- rbindlist(results_list, fill = TRUE)
fwrite(results_dt, "../../output/tgep_results.csv")
cat("Stability analysis complete.\n")
