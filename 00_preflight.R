# Purpose: verify runtime, directories, required inputs, and package availability.
# Inputs: project directory, public-source files already downloaded when available.
# Outputs: preflight report and environment snapshots under 05_results/qc and 09_environment.
# Dependencies: base R; optional analysis packages are checked but do not block audit.
# Run order: first script in run_all.ps1.

set.seed(20260903)
source("04_scripts/_common.R")
ensure_project_dirs()
log_event("START 00_preflight")

required <- c(
  "GSE111782/ GSE111782_series_matrix.txt.gz",
  "GSE311535/ GSE311535_carotid_plaque_counts_matrix.txt.gz",
  "GSE260657/ GSE260657_family.soft.gz"
)
required_paths <- file.path(project_root, "03_data/raw", trimws(gsub("^([^/]+)/\\s+", "\\1/", required)))
file_check <- data.frame(
  item = required,
  exists = file.exists(required_paths),
  path = required_paths,
  size_bytes = ifelse(file.exists(required_paths), file.info(required_paths)$size, NA_real_),
  stringsAsFactors = FALSE
)
safe_write_csv(file_check, "05_results/qc/preflight_file_check.csv")

packages <- c(
  "limma", "edgeR", "GEOquery", "Biobase", "hgu133a2.db", "GSVA",
  "GSEABase", "org.Hs.eg.db", "AnnotationDbi", "fgsea",
  "clusterProfiler", "ReactomePA", "ggplot2", "pheatmap", "RColorBrewer"
)
pkg_check <- data.frame(
  package = packages,
  installed = vapply(packages, requireNamespace, logical(1), quietly = TRUE),
  version = vapply(packages, function(p) {
    if (requireNamespace(p, quietly = TRUE)) as.character(packageVersion(p)) else NA_character_
  }, character(1)),
  stringsAsFactors = FALSE
)
safe_write_csv(pkg_check, "09_environment/package_check.csv")

capture.output(sessionInfo(), file = "09_environment/session_info.txt")
write.csv(as.data.frame(installed.packages()[, c("Package", "Version", "LibPath")]),
          "09_environment/package_versions.csv", row.names = FALSE)
writeLines(c(
  "Preflight completed.",
  paste0("R version: ", R.version.string),
  "Seed: 20260903",
  paste0("Working directory: ", project_root),
  paste0("Missing required files: ", sum(!file_check$exists)),
  paste0("Missing optional/core packages: ", sum(!pkg_check$installed))
), "05_results/qc/preflight_summary.txt")

log_event("END 00_preflight status=0")

