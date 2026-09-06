# Purpose: document spatial-data search and strict enable/disable status.
# Inputs: dataset audit and available public spatial resources.
# Outputs: spatial validation status; no unsupported spatial claims.
# Dependencies: base R.
# Run order: after 08_cell_communication_optional.

set.seed(20260903)
source("04_scripts/_common.R")
ensure_project_dirs()
write_status("05_results/qc/spatial_validation_status.md", "Spatial validation status",
             c("NOT RUN: no quality-verified human carotid plaque spatial transcriptomics dataset was identified in the current audit.",
               "Non-carotid spatial data are not used as primary evidence.",
               "No spatial proximity or co-localization claim is made."))
log_event("END 09_spatial_validation_optional status=0")

