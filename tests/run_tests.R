args <- commandArgs(trailingOnly = FALSE)
script_arg <- grep("^--file=", args, value = TRUE)

resolve_project_root <- function() {
  candidates <- c(
    normalizePath(getwd(), winslash = "/", mustWork = FALSE),
    if (length(script_arg) > 0) {
      normalizePath(file.path(dirname(sub("^--file=", "", script_arg[[1]])), ".."), winslash = "/", mustWork = FALSE)
    },
    normalizePath("..", winslash = "/", mustWork = FALSE)
  )
  candidates <- unique(candidates[nzchar(candidates)])

  for (candidate in candidates) {
    if (file.exists(file.path(candidate, "tests", "test_logic.R"))) {
      return(candidate)
    }
  }

  stop("Project root not found. Run from the repo root or invoke this script via Rscript.")
}

setwd(resolve_project_root())

# Fail closed if testthat is unavailable. Previously this script swallowed the
# missing-package error and still exited 0, so the pytest contract
# (test_r_logic_suite_passes_when_rscript_is_available) reported a false PASS
# while the 37 R assertions never actually ran.
if (!requireNamespace("testthat", quietly = TRUE)) {
  cat("ERROR: package 'testthat' is not installed.",
      "Install it with install.packages('testthat') to run the R logic suite.\n")
  quit(status = 2, save = "no")
}

# Run the suite and propagate real failures as a non-zero exit status so the
# harness cannot mistake a broken/skipped run for a green one. test_file()
# returns a data.frame-coercible result with `failed` and `error` columns.
results <- as.data.frame(testthat::test_file(
  "tests/test_logic.R",
  reporter = "silent"
))

n_fail <- sum(results$failed, na.rm = TRUE)
n_error <- sum(as.logical(results$error), na.rm = TRUE)
n_pass <- sum(results$passed, na.rm = TRUE)

if (n_fail > 0L || n_error > 0L) {
  cat(sprintf("R logic suite FAILED: %d failure(s), %d error(s), %d pass.\n",
              n_fail, n_error, n_pass))
  quit(status = 1, save = "no")
}
cat(sprintf("R logic suite passed: %d assertions.\n", n_pass))
