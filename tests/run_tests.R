setwd("C:/Models/HTA_Unified_Intelligence_System")
tryCatch(
  testthat::test_file("tests/test_logic.R"),
  error = function(e) cat("ERROR:", conditionMessage(e), "\n")
)
