# Purpose: compare discovery-derived directions and signatures in the independent bulk cohort.
# Inputs: GSE111782 DEG/signature outputs and GSE311535 DEG/signature outputs.
# Outputs: direction concordance, candidate-gene validation, and non-significant/inconsistent results.
# Dependencies: base R.
# Run order: after 04_signature_and_enrichment and before figures/manuscript.

set.seed(20260903)
source("04_scripts/_common.R")
ensure_project_dirs()
log_event("START 10_external_validation")

d1 <- read.csv("05_results/tables/GSE111782_DEG_complete.csv", check.names = FALSE)
d2 <- read.csv("05_results/tables/GSE311535_DEG_complete.csv", check.names = FALSE)
s <- read.csv("05_results/tables/signature_scores.csv", check.names = FALSE)

merged <- merge(d1[, c("gene", "logFC", "P_value", "FDR")],
                d2[, c("gene", "logFC", "P_value", "FDR")],
                by = "gene", suffixes = c("_discovery", "_validation"))
merged$direction_concordant <- sign(merged$logFC_discovery) == sign(merged$logFC_validation)
merged$discovery_FDR_lt_05 <- merged$FDR_discovery < 0.05
merged$validation_FDR_lt_05 <- merged$FDR_validation < 0.05
merged$validation_status <- ifelse(merged$discovery_FDR_lt_05 & merged$validation_FDR_lt_05 &
                                     merged$direction_concordant, "concordant_FDR_supported",
                                   ifelse(merged$direction_concordant, "direction_concordant_only",
                                          "inconsistent_direction"))
safe_write_csv(merged, "05_results/tables/external_validation_gene_direction.csv")

sig_summary <- do.call(rbind, lapply(intersect(unique(s$cohort), c("GSE111782", "GSE311535")), function(cohort) {
  d <- s[s$cohort == cohort, , drop = FALSE]
  out <- lapply(setdiff(names(d), c("sample", "group", "cohort")), function(sig) {
    tt <- wilcox.test(d[[sig]] ~ d$group, exact = FALSE)
    data.frame(cohort = cohort, signature = sig, n = nrow(d),
               median_asymptomatic = median(d[[sig]][d$group == "asymptomatic"], na.rm = TRUE),
               median_symptomatic = median(d[[sig]][d$group == "symptomatic"], na.rm = TRUE),
               P_value = tt$p.value, stringsAsFactors = FALSE)
  })
  do.call(rbind, out)
}))
sig_summary$FDR <- bh(sig_summary$P_value)
safe_write_csv(sig_summary, "05_results/tables/external_validation_signature_summary.csv")

writeLines(c(
  "Validation is reported as a separate cohort and is not merged with discovery.",
  "Concordant directions without FDR support are labeled direction_concordant_only.",
  "Inconsistent directions are retained and should be discussed by cohort, platform, disease stage, and sample size."
), "05_results/qc/external_validation_interpretation.txt")
log_event("END 10_external_validation status=0")

