# R Dependency Setup
packages <- c("data.table", "dplyr", "ggplot2")
install_if_missing <- function(p) {
  if (!require(p, character.only = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
}
invisible(sapply(packages, install_if_missing))
print("All R dependencies satisfied.")
