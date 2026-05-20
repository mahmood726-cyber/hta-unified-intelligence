# R Dependency Setup
packages <- c(
  "data.table",
  "dplyr",
  "ggplot2",
  "jsonlite",
  "metafor",
  "testthat"
)

install_if_missing <- function(p) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
}
invisible(sapply(packages, install_if_missing))
cat("All R dependencies satisfied.\n")
