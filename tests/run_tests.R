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
tryCatch(
  testthat::test_file("tests/test_logic.R"),
  error = function(e) cat("ERROR:", conditionMessage(e), "\n")
)
