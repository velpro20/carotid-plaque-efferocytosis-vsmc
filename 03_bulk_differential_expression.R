# Purpose: calculate bulk differential expression in discovery and validation cohorts.
# Inputs: processed GSE111782 expression and GSE311535 counts.
# Outputs: complete DEG tables with gene, effect, statistic, P value, FDR, and mean expression.
# Dependencies: limma and edgeR.
# Run order: after 02_bulk_qc_and_preprocess and before signatures/enrichment.

set.seed(20260903)
source("04_scripts/_common.R")
ensure_project_dirs()
log_event("START 03_bulk_differential_expression")

## Discovery limma
expr111 <- readRDS("03_data/processed/GSE111782_expression_gene.rds")
meta111 <- read.csv("03_data/processed/GSE111782_sample_metadata.csv", check.names = FALSE)
meta111$group <- factor(meta111$group, levels = c("asymptomatic", "symptomatic"))
design111 <- model.matrix(~ group, data = meta111)
fit111 <- limma::lmFit(expr111[, meta111$sample, drop = FALSE], design111)
fit111 <- limma::eBayes(fit111, robust = TRUE)
coef_idx <- which(colnames(design111) == "groupsymptomatic" | colnames(design111) == "group1")
if (!length(coef_idx)) coef_idx <- 2L
top111 <- limma::topTable(fit111, coef = coef_idx[1], number = Inf, sort.by = "none")
top111$gene <- rownames(top111)
top111$SE <- fit111$stdev.unscaled[, coef_idx[1]] * fit111$sigma
top111$statistic <- fit111$t[, coef_idx[1]]
top111$P_value <- top111$P.Value
top111$FDR <- top111$adj.P.Val
top111$mean_expression <- top111$AveExpr
top111 <- top111[, c("gene", "logFC", "SE", "statistic", "P_value", "FDR", "mean_expression",
                     setdiff(names(top111), c("gene", "logFC", "SE", "statistic", "P_value",
                                              "FDR", "mean_expression"))), drop = FALSE]
safe_write_csv(top111, "05_results/tables/GSE111782_DEG_complete.csv")
saveRDS(fit111, "03_data/processed/GSE111782_limma_fit.rds")

## Validation edgeR QL model
counts311 <- readRDS("03_data/processed/GSE311535_counts.rds")
meta311 <- read.csv("03_data/processed/GSE311535_sample_metadata.csv", check.names = FALSE)
meta311$group <- factor(meta311$group, levels = c("asymptomatic", "symptomatic"))
y <- edgeR::DGEList(counts = counts311, group = meta311$group)
keep <- edgeR::filterByExpr(y, group = meta311$group)
y <- y[keep, , keep.lib.sizes = FALSE]
y <- edgeR::calcNormFactors(y)
design311 <- model.matrix(~ group, data = meta311)
y <- edgeR::estimateDisp(y, design311)
fit311 <- edgeR::glmQLFit(y, design311, robust = TRUE)
coef311 <- which(colnames(design311) == "groupsymptomatic" | colnames(design311) == "group1")
if (!length(coef311)) coef311 <- 2L
test311 <- edgeR::glmQLFTest(fit311, coef = coef311[1])
top311 <- edgeR::topTags(test311, n = Inf, sort.by = "none")$table
top311$gene <- rownames(top311)
top311$SE <- NA_real_
top311$statistic <- top311$F
top311$P_value <- top311$PValue
top311$FDR <- top311$FDR
top311$mean_expression <- top311$logCPM
top311 <- top311[, c("gene", "logFC", "SE", "statistic", "P_value", "FDR", "mean_expression",
                     setdiff(names(top311), c("gene", "logFC", "SE", "statistic", "P_value",
                                              "FDR", "mean_expression"))), drop = FALSE]
safe_write_csv(top311, "05_results/tables/GSE311535_DEG_complete.csv")
saveRDS(fit311, "03_data/processed/GSE311535_edgeR_qlfit.rds")

## Cohort-level result summary
summary_df <- data.frame(
  cohort = c("GSE111782", "GSE311535"),
  model = c("limma empirical Bayes linear model", "edgeR quasi-likelihood negative-binomial model"),
  n_asymptomatic = c(sum(meta111$group == "asymptomatic"), sum(meta311$group == "asymptomatic")),
  n_symptomatic = c(sum(meta111$group == "symptomatic"), sum(meta311$group == "symptomatic")),
  n_genes_tested = c(nrow(top111), nrow(top311)),
  FDR_threshold = 0.05,
  stringsAsFactors = FALSE
)
safe_write_csv(summary_df, "05_results/tables/bulk_analysis_summary.csv")
log_event("END 03_bulk_differential_expression status=0")

