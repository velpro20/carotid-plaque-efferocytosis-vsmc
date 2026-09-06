# Purpose: record strict enable/disable status for predicted cell communication.
# Inputs: scRNA annotation and program-score outputs.
# Outputs: complete status record; no communication inference when gates are unmet.
# Dependencies: base R; communication packages are intentionally optional.
# Run order: after 07_scrna_macrophage_vsmc.

set.seed(20260903)
source("04_scripts/_common.R")
ensure_project_dirs()
log_event("START 08_cell_communication_optional")

score_path <- "05_results/tables/GSE260657_cell_program_scores.csv"
if (!file.exists(score_path)) {
  write_status("05_results/qc/cell_communication_status.md", "Cell communication status",
               c("NOT RUN: macrophage/VSMC cell-level scores are unavailable.",
                 "No predicted ligand-receptor interaction is reported."))
} else {
  x <- read.csv(score_path, check.names = FALSE)
  if (length(unique(x$file)) < 2L) {
    write_status("05_results/qc/cell_communication_status.md", "Cell communication status",
                 c("NOT RUN: insufficient sample/file structure for a donor-aware analysis.",
                   "No predicted ligand-receptor interaction is reported."))
  } else {
    write_status("05_results/qc/cell_communication_status.md", "Cell communication status",
                 c("NOT RUN by default: a validated ligand-receptor database, reliable cell annotations, and donor-aware thresholds were not all verified.",
                   "This optional module is not part of the primary evidence."))
  }
}
log_event("END 08_cell_communication_optional status=0")

