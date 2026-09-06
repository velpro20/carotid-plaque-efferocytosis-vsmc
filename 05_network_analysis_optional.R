# Purpose: run WGCNA only when the prespecified sample-size and stability gates are met.
# Inputs: discovery expression matrix and sample metadata.
# Outputs: WGCNA skip record or network diagnostic/results tables.
# Dependencies: WGCNA only if installed; base R otherwise.
# Run order: after 04_signature_and_enrichment.

set.seed(20260903)
source("04_scripts/_common.R")
ensure_project_dirs()
log_event("START 05_network_analysis_optional")

expr <- readRDS("03_data/processed/GSE111782_expression_gene.rds")
n <- ncol(expr)
if (n < 30L || !requireNamespace("WGCNA", quietly = TRUE)) {
  reason <- if (n < 30L) sprintf("Skipped: discovery post-QC sample count is %d, below prespecified minimum 30.", n)
            else "Skipped: WGCNA package is unavailable."
  write_status("05_results/qc/WGCNA_status.md", "WGCNA status",
               c(reason, "No network hub claims are made."))
  log_event(paste("WGCNA", reason))
} else {
  dat <- t(expr)
  dat <- dat[, apply(dat, 2, sd, na.rm = TRUE) > 0, drop = FALSE]
  gsg <- WGCNA::goodSamplesGenes(dat, verbose = 0)
  dat <- dat[gsg$goodSamples, gsg$goodGenes, drop = FALSE]
  powers <- 1:10
  sft <- WGCNA::pickSoftThreshold(dat, powerVector = powers, verbose = 0)
  safe_write_csv(as.data.frame(sft$fitIndices), "05_results/tables/WGCNA_soft_threshold.csv")
  write_status("05_results/qc/WGCNA_status.md", "WGCNA status",
               c("WGCNA ran because the prespecified sample-size gate was met.",
                 "All network genes and modules are exploratory; central genes are hub candidates only."))
}
log_event("END 05_network_analysis_optional status=0")

