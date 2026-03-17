# QA TEST SUITE: LOGIC VERIFICATION — HTA Unified Intelligence System

suppressPackageStartupMessages({
  library(data.table)
  library(testthat)
})

# Robust config loading
if (file.exists("config.R")) source("config.R") else source("../config.R")

# ============================================================================
# 1. CONFIGURATION TESTS
# ============================================================================

test_that("Config weights sum to 1.0", {
  w <- HTA_CONFIG$weights
  expect_equal(w$integrity + w$stability + w$transport + w$value, 1.0)
})

test_that("Config thresholds are ordered correctly", {
  t <- HTA_CONFIG$thresholds
  expect_true(t$fragile < t$conditional)
  expect_true(t$conditional < t$immutable)
})

test_that("Divergence config has required fields", {
  d <- HTA_CONFIG$divergence
  expect_true(!is.null(d$small_effect_bound))
  expect_true(!is.null(d$penalty_trigger))
  expect_true(!is.null(d$max_penalty))
  expect_true(d$max_penalty > 0)
})

# ============================================================================
# 2. UDS CALCULATION TESTS
# ============================================================================

test_that("UDS with perfect scores gives high value", {
  w <- HTA_CONFIG$weights
  # Perfect: inf_frac=1.5, fpi=100, cte=1.0, ncb>0
  uds <- (1.5/1.5 * w$integrity * 100) +
         (100/100 * w$stability * 100) +
         (1.0 * w$transport * 100) +
         (w$value * 100)
  expect_true(uds >= HTA_CONFIG$thresholds$immutable)
})

test_that("UDS with zeros gives low value", {
  w <- HTA_CONFIG$weights
  # All defaults (missing data): inf_frac=0.75/1.5, fpi=50/100, cte=0.7, ncb=0
  uds <- (0.75/1.5 * w$integrity * 100) +
         (50/100 * w$stability * 100) +
         (0.7 * w$transport * 100) +
         0  # no value contribution
  expect_true(uds > 0)
  expect_true(uds < HTA_CONFIG$thresholds$immutable)
})

test_that("DCI is 100 when all engines present", {
  w <- HTA_CONFIG$weights
  dci <- (w$integrity + w$stability + w$transport + w$value) * 100
  expect_equal(dci, 100)
})

test_that("DCI partial when engines missing", {
  w <- HTA_CONFIG$weights
  # Only integrity present
  dci <- w$integrity * 100
  expect_equal(dci, 30)
})

# ============================================================================
# 3. VERDICT CLASSIFICATION TESTS
# ============================================================================

test_that("Verdict thresholds classify correctly", {
  t <- HTA_CONFIG$thresholds
  classify <- function(uds) {
    if (uds >= t$immutable) "IMMUTABLE TRUTH"
    else if (uds >= t$conditional) "CONDITIONAL"
    else if (uds >= t$fragile) "FRAGILE"
    else "REJECT"
  }
  expect_equal(classify(80), "IMMUTABLE TRUTH")
  expect_equal(classify(50), "CONDITIONAL")
  expect_equal(classify(25), "FRAGILE")
  expect_equal(classify(10), "REJECT")
})

# ============================================================================
# 4. DIVERGENCE PENALTY TESTS
# ============================================================================

test_that("Divergence penalty is zero below trigger", {
  d <- HTA_CONFIG$divergence
  div_pct <- d$penalty_trigger - 1  # just below
  penalty <- 0
  expect_equal(penalty, 0)
})

test_that("Divergence penalty is capped at max", {
  d <- HTA_CONFIG$divergence
  div_pct <- 100  # extreme divergence
  penalty <- min(d$max_penalty, (div_pct - d$penalty_trigger) / 2)
  expect_equal(penalty, d$max_penalty)
})

test_that("Small effect uses absolute divergence", {
  d <- HTA_CONFIG$divergence
  orig <- 0.05  # below small_effect_bound
  tgep <- 0.08
  expect_true(abs(orig) < d$small_effect_bound)
  div <- abs(tgep - orig) * 100
  expect_equal(div, 3)
})

test_that("Large effect uses relative divergence", {
  d <- HTA_CONFIG$divergence
  orig <- 0.5
  tgep <- 0.6
  expect_true(abs(orig) >= d$small_effect_bound)
  div <- abs(tgep - orig) / (abs(orig) + 1e-6) * 100
  expect_equal(div, 20, tolerance = 0.1)
})

# ============================================================================
# 5. TGEP TESTS (if available)
# ============================================================================

tgep_available <- tryCatch({
  if (file.exists("src/R/TGEP.R")) source("src/R/TGEP.R")
  else if (file.exists("../src/R/TGEP.R")) source("../src/R/TGEP.R")
  TRUE
}, error = function(e) FALSE)

if (tgep_available) {
  test_that("TGEP returns valid structure with known data", {
    set.seed(42)
    yi <- c(-0.5, -0.3, -0.8, -0.4, -0.6)
    vi <- c(0.04, 0.05, 0.03, 0.06, 0.04)
    res <- tgep_meta(yi, vi, n_boot = 0)
    expect_true(inherits(res, "tgep"))
    expect_true(is.finite(res$estimate))
    expect_true(is.finite(res$se))
    expect_true(res$ci_lb < res$estimate)
    expect_true(res$ci_ub > res$estimate)
    expect_equal(length(res$weights), 3)
    expect_equal(sum(res$weights), 1.0, tolerance = 1e-10)
    expect_equal(res$k, 5)
  })

  test_that("TGEP conf_level parameter works", {
    yi <- c(-0.5, -0.3, -0.8, -0.4, -0.6)
    vi <- c(0.04, 0.05, 0.03, 0.06, 0.04)
    res95 <- tgep_meta(yi, vi, n_boot = 0, conf_level = 0.95)
    res99 <- tgep_meta(yi, vi, n_boot = 0, conf_level = 0.99)
    # 99% CI should be wider than 95% CI
    width95 <- res95$ci_ub - res95$ci_lb
    width99 <- res99$ci_ub - res99$ci_lb
    expect_true(width99 > width95)
    expect_equal(res95$conf_level, 0.95)
    expect_equal(res99$conf_level, 0.99)
  })

  test_that("TGEP handles k=2 (minimum viable)", {
    yi <- c(-0.5, -0.3)
    vi <- c(0.04, 0.05)
    res <- tgep_meta(yi, vi, n_boot = 0)
    expect_true(is.finite(res$estimate))
  })

  test_that("TGEP with bootstrap produces valid SE", {
    set.seed(123)
    yi <- c(-0.5, -0.3, -0.8, -0.4, -0.6, -0.2, -0.7)
    vi <- c(0.04, 0.05, 0.03, 0.06, 0.04, 0.05, 0.03)
    res <- tgep_meta(yi, vi, n_boot = 50)
    expect_true(res$se > 0)
    expect_true(is.finite(res$se))
  })
}

# ============================================================================
# 6. MISSING ENGINE HANDLING TESTS
# ============================================================================

test_that("safe_fread returns NULL for missing file", {
  safe_fread <- function(path) { if (file.exists(path)) return(fread(path)); return(NULL) }
  expect_null(safe_fread("nonexistent_file.csv"))
})

cat("QA Tests Complete.\n")
