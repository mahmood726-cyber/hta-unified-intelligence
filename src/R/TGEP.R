#' TGEP: Triple-Guard Ensemble Pooling for Meta-Analysis
#'
#' @author Mahmood Ul Hassan
#' @date 2026-02-15

library(metafor)
library(parallel)

# ============================================================================
# GUARD CORES (Returning both Estimate and estimated Variance)
# ============================================================================

grma_guard_core <- function(y, v, zeta = 0.5) {
  n <- length(y)
  if (n < 2) return(list(est = median(y), var = var(y)/n))
  prec <- 1.0 / v
  log_prec <- log(prec + 1.0)
  robust_scale <- function(x) {
    q <- quantile(x, c(0.05, 0.95), na.rm = TRUE)
    rng <- q[2] - q[1]
    if (rng < 1e-12) rng <- 1.0
    pmin(pmax((x - q[1]) / rng, 0.0), 1.0)
  }
  x_eff <- robust_scale(y); x_pre <- robust_scale(log_prec)
  a_y <- median(y); a_p <- max(prec)
  q_y <- quantile(y, c(0.05, 0.95), na.rm = TRUE)
  a_eff <- pmin(pmax((a_y - q_y[1]) / (q_y[2] - q_y[1] + 1e-12), 0.0), 1.0)
  q_p <- quantile(log_prec, c(0.05, 0.95), na.rm = TRUE)
  a_pre <- pmin(pmax((log(a_p + 1.0) - q_p[1]) / (q_p[2] - q_p[1] + 1e-12), 0.0), 1.0)
  delta_eff <- abs(x_eff - a_eff); delta_pre <- abs(x_pre - a_pre)
  d_min <- min(c(delta_eff, delta_pre)); d_max <- max(c(delta_eff, delta_pre))
  grc <- ((d_min + zeta * d_max) / (delta_eff + zeta * d_max) + 
          (d_min + zeta * d_max) / (delta_pre + zeta * d_max)) / 2.0
  w <- grc / sum(grc)
  list(est = sum(w * y), var = sum(w^2 * v))
}

wrd_guard_core <- function(y, v, threshold = 2.5, method = "REML") {
  if (length(y) < 2) return(list(est = median(y), var = var(y)/length(y)))
  fit <- tryCatch(rma(y, v, method = method), error = function(e) list(beta = median(y), tau2 = var(y)/2))
  est <- as.numeric(fit$beta); tau2 <- if(is.null(fit$tau2) || is.na(fit$tau2)) 0 else fit$tau2
  z <- (y - est) / sqrt(v + tau2)
  y_win <- est + pmin(pmax(z, -threshold), threshold) * sqrt(v + tau2)
  w <- 1 / (v + tau2)
  list(est = sum(w * y_win) / sum(w), var = 1 / sum(w))
}

swa_guard_core <- function(y, v, p_cutoff = 0.05, method = "REML") {
  if (length(y) < 2) return(list(est = median(y), var = var(y)/length(y)))
  fit <- tryCatch(rma(y, v, method = method), error = function(e) list(beta = median(y), tau2 = var(y)/2))
  est <- as.numeric(fit$beta); tau2 <- if(is.null(fit$tau2) || is.na(fit$tau2)) 0 else fit$tau2
  p <- 2 * (1 - pnorm(abs(y / sqrt(v + tau2))))
  w_iv <- 1 / (v + tau2)
  w_swa <- w_iv / ifelse(p < p_cutoff, 1.0, 0.4)
  w_norm <- w_swa / sum(w_swa)
  list(est = sum(w_norm * y), var = sum(w_norm^2 * (v + tau2)))
}

# ============================================================================
# TGEP CORE
# ============================================================================

tgep_meta <- function(yi, vi, n_boot = 100, temperature = 1.0, n_cores = 1, conf_level = 0.95) {
  k <- length(yi)
  guards <- list(GRMA = grma_guard_core, WRD = wrd_guard_core, SWA = swa_guard_core)
  
  get_weights <- function(errors, temp) {
    if (max(errors) - min(errors) < 1e-12) return(rep(1/length(errors), length(errors)))
    scaled_err <- (errors - min(errors)) / (max(errors) - min(errors) + 1e-12)
    w <- exp(-scaled_err / temp); w / sum(w)
  }

  compute_tgep_internal <- function(y, v, temp) {
    kk <- length(y)
    guard_results <- lapply(guards, function(f) f(y, v))
    ests <- sapply(guard_results, function(r) r$est)
    vars <- sapply(guard_results, function(r) r$var)
    
    if (kk < 3) return(list(est = median(y), weights = rep(1/3, 3), guard_ests = ests, guard_vars = vars))

    # For large k, use FE in LOO for speed (REML LOO is O(k * REML_iter))
    loo_method <- if (kk > 15) "FE" else "REML"
    loo_guards <- list(GRMA = grma_guard_core,
                       WRD = function(y, v) wrd_guard_core(y, v, method = loo_method),
                       SWA = function(y, v) swa_guard_core(y, v, method = loo_method))

    loo_errs <- matrix(0, nrow = kk, ncol = 3)
    for (i in 1:kk) {
      y_m <- y[-i]; v_m <- v[-i]
      for (j in 1:3) {
        est_ij <- tryCatch(loo_guards[[j]](y_m, v_m)$est, error = function(e) median(y_m))
        loo_errs[i, j] <- (y[i] - est_ij)^2 / v[i]
      }
    }
    w <- get_weights(colMeans(loo_errs), temp)
    list(est = sum(w * ests), weights = w, guard_ests = ests, guard_vars = vars, scores = colMeans(loo_errs))
  }

  main_res <- compute_tgep_internal(yi, vi, temperature)

  # Bootstrap for SE (Accounts for model uncertainty)
  if (n_boot > 0) {
    if (n_cores > 1 && .Platform$OS.type != "windows") {
      boot_est <- unlist(mclapply(1:n_boot, function(b) {
        idx <- sample(1:k, k, replace = TRUE)
        tryCatch(compute_tgep_internal(yi[idx], vi[idx], temperature)$est, error = function(e) NA)
      }, mc.cores = n_cores))
    } else {
      boot_est <- replicate(n_boot, {
        idx <- sample(1:k, k, replace = TRUE)
        tryCatch(compute_tgep_internal(yi[idx], vi[idx], temperature)$est, error = function(e) NA)
      })
    }
    boot_est <- boot_est[!is.na(boot_est) & is.finite(boot_est)]
    se <- if(length(boot_est) > 5) sd(boot_est) else sqrt(sum(main_res$weights^2 * main_res$guard_vars))
  } else {
    # Analytical approximation (Conservative)
    se <- sqrt(sum(main_res$weights^2 * main_res$guard_vars))
  }

  z_crit <- qnorm(1 - (1 - conf_level) / 2)
  res <- list(estimate = main_res$est, se = se, ci_lb = main_res$est - z_crit*se,
              ci_ub = main_res$est + z_crit*se, pvalue = 2*(1-pnorm(abs(main_res$est/se))),
              weights = main_res$weights, guards = main_res$guard_ests, k = k, temp = temperature,
              conf_level = conf_level)
  class(res) <- "tgep"
  res
}

# ============================================================================
# DIAGNOSTICS & PLOTTING
# ============================================================================

plot.tgep <- function(x, ...) {
  par(mfrow=c(1,2))
  barplot(x$weights, names.arg=names(x$weights), col=c("skyblue", "coral", "lightgreen"),
          main="Guard Weights", ylab="Weight")
  ests <- c(x$guards, Ensemble = x$estimate)
  cols <- c(rep("grey80", 3), "red")
  pch <- c(rep(1, 3), 19)
  plot(ests, 1:4, pch=pch, col=cols, yaxt="n", xlab="Effect Size", ylab="", 
       main="Guard vs. Ensemble", xlim=range(c(x$ci_lb, x$ci_ub, x$guards)))
  axis(2, at=1:4, labels=names(ests), las=1)
  segments(x$ci_lb, 4, x$ci_ub, 4, col="red", lwd=2)
  par(mfrow=c(1,1))
}

plot_sparsity <- function(yi, vi, temps = c(0.01, 0.1, 0.5, 1, 5, 10)) {
  weights_mat <- sapply(temps, function(t) tgep_meta(yi, vi, n_boot=0, temperature=t)$weights)
  matplot(temps, t(weights_mat), type="b", log="x", pch=19, 
          col=c("skyblue", "coral", "lightgreen"), lty=1,
          xlab="Temperature (log scale)", ylab="Weight", main="Guard Sparsity vs. Temperature")
  legend("topright", legend=c("GRMA", "WRD", "SWA"), col=c("skyblue", "coral", "lightgreen"), pch=19)
}
