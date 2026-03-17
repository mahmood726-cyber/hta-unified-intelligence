# HTA UNIFIED INTELLIGENCE SYSTEM: METHODOLOGY CONFIGURATION (V2)
# Centralizing all thresholds and weights for regulatory transparency

HTA_CONFIG <- list(
  # --- Pillar Weights ---
  weights = list(
    integrity = 0.30,
    stability = 0.25,
    transport = 0.25,
    value     = 0.20
  ),
  
  # --- Thresholds ---
  thresholds = list(
    conditional = 40,
    immutable   = 70,
    fragile     = 20
  ),
  
  # --- Divergence (TGEP) ---
  divergence = list(
    small_effect_bound = 0.1,
    penalty_trigger    = 20,
    max_penalty        = 10
  ),
  
  # --- Economic Sensitivity ---
  economics = list(
    wtp_threshold = 50000, # Willingness to Pay per QALY/Unit
    value_scaling = 1.2    # Multiplier for high-value evidence
  ),
  
  # --- Stability (LOO) ---
  stability = list(
    loo_flip_penalty = 15 # Points to deduct if 1 study flips the verdict
  )
)

cat("Methodology Configuration V2 Loaded.\n")
