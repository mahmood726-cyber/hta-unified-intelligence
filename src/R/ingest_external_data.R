#!/usr/bin/env Rscript

# INGEST EXTERNAL DATA
# Converts user CSVs in data/input/ into .rda format for TGEP

suppressPackageStartupMessages({
  library(data.table)
})

input_dir <- "data/input"
output_dir <- "../Pairwise70/data" # Inject into TGEP source

if (!dir.exists(input_dir)) {
  dir.create(input_dir, recursive = TRUE)
  cat("Created data/input/ folder. Drop your CSVs here.\n")
  cat("Format: yi (effect size), vi (variance) OR se (standard error)\n")
}

files <- list.files(input_dir, pattern = "\\.csv$", full.names = TRUE)

if (length(files) > 0) {
  for (f in files) {
    dt <- fread(f)
    if (!"yi" %in% names(dt)) {
      cat(sprintf("Skipping %s: Missing 'yi' column.\n", f))
      next
    }
    
    # Standardize
    if (!"vi" %in% names(dt) && "se" %in% names(dt)) dt[, vi := se^2]
    
    name <- tools::file_path_sans_ext(basename(f))
    assign(name, dt)
    save(list = name, file = file.path(output_dir, paste0(name, ".rda")))
    cat(sprintf("Ingested: %s -> %s.rda\n", f, name))
  }
} else {
  cat("No new CSVs found in data/input/.\n")
}
