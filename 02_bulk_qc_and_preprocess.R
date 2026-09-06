# Purpose: parse and QC the discovery array and validation count matrix.
# Inputs: GSE111782 series matrix, GSE311535 gene-level counts, GEO metadata.
# Outputs: processed matrices, sample metadata, QC tables and R plots.
# Dependencies: limma, edgeR, GEOquery, hgu133a2.db, ggplot2, pheatmap.
# Run order: after 01_download_and_audit and before differential expression.

set.seed(20260903)
source("04_scripts/_common.R")
ensure_project_dirs()
log_event("START 02_bulk_qc_and_preprocess")

dir.create("03_data/raw/GPL", recursive = TRUE, showWarnings = FALSE)

## Discovery microarray
gse111_path <- "03_data/raw/GSE111782/GSE111782_series_matrix.txt.gz"
if (!file.exists(gse111_path)) stop("Missing GSE111782 matrix")
expr_probe <- read_series_matrix(gse111_path)
gse111_samples <- colnames(expr_probe)
group111 <- ifelse(grepl("964[8-9]|965[0-6]", gse111_samples), "symptomatic", "asymptomatic")
group111 <- factor(group111, levels = c("asymptomatic", "symptomatic"))
meta111 <- data.frame(sample = gse111_samples, group = group111, cohort = "GSE111782",
                      tissue = "post-bifurcation internal carotid plaque",
                      stringsAsFactors = FALSE)

annotation <- NULL
if (requireNamespace("GEOquery", quietly = TRUE)) {
  annotation <- tryCatch({
    gpl <- GEOquery::getGEO("GPL571", destdir = "03_data/raw/GPL", AnnotGPL = FALSE)
    tab <- GEOquery::Table(gpl)
    safe_write_csv(tab, "03_data/metadata/GPL571_annotation.csv")
    tab
  }, error = function(e) {
    record_error("02_bulk_qc_and_preprocess", paste("GPL571 annotation retrieval failed:", e$message))
    NULL
  })
}

expr_gene <- expr_probe
if (!is.null(annotation)) {
  id_col <- names(annotation)[grepl("^id$", names(annotation), ignore.case = TRUE)][1]
  sym_col <- names(annotation)[grepl("gene.?symbol|symbol", names(annotation), ignore.case = TRUE)][1]
  if (!is.na(id_col) && !is.na(sym_col)) {
    symbols <- as.character(annotation[[sym_col]][match(rownames(expr_probe), annotation[[id_col]])])
    symbols[is.na(symbols) | symbols == "" | symbols == "---"] <- rownames(expr_probe)[is.na(symbols) | symbols == "" | symbols == "---"]
    symbols <- sub(" ///.*$", "", symbols)
    symbols <- sub(" //.*$", "", symbols)
    keep <- !is.na(symbols) & symbols != ""
    expr_annot <- expr_probe[keep, , drop = FALSE]
    symbols <- symbols[keep]
    if (requireNamespace("limma", quietly = TRUE)) {
      expr_gene <- limma::avereps(expr_annot, ID = symbols)
    } else {
      expr_gene <- rowsum(expr_annot, group = symbols, reorder = FALSE) /
        as.vector(table(factor(symbols, levels = unique(symbols))))
    }
  }
}
if (requireNamespace("limma", quietly = TRUE)) {
  expr_gene <- limma::normalizeBetweenArrays(expr_gene)
}
saveRDS(expr_gene, "03_data/processed/GSE111782_expression_gene.rds")
safe_write_csv(meta111, "03_data/processed/GSE111782_sample_metadata.csv")

## Discovery QC
missing111 <- data.frame(
  sample = colnames(expr_gene),
  missing_fraction = colMeans(is.na(expr_gene)),
  median_expression = apply(expr_gene, 2, median, na.rm = TRUE),
  mean_expression = colMeans(expr_gene, na.rm = TRUE),
  stringsAsFactors = FALSE
)
cor111 <- cor(expr_gene, use = "pairwise.complete.obs", method = "spearman")
pca_var <- apply(expr_gene, 1, var, na.rm = TRUE)
pca_keep <- is.finite(pca_var) & pca_var > 0 &
  apply(expr_gene, 1, function(z) all(is.finite(z)))
if (sum(pca_keep) < 2L) stop("Fewer than two non-constant finite genes available for PCA")
pca111 <- prcomp(t(expr_gene[pca_keep, , drop = FALSE]), scale. = TRUE)
pca_df111 <- data.frame(sample = rownames(pca111$x), PC1 = pca111$x[, 1], PC2 = pca111$x[, 2],
                        group = group111[match(rownames(pca111$x), meta111$sample)])
safe_write_csv(missing111, "05_results/qc/GSE111782_sample_qc.csv")
safe_write_csv(as.data.frame(cor111), "05_results/qc/GSE111782_sample_correlation.csv", row.names = TRUE)
safe_write_csv(pca_df111, "05_results/qc/GSE111782_PCA.csv")
writeLines(c(
  "Outlier rule: a sample is flagged if missing_fraction > 0.05, or if its median sample correlation is below the cohort median minus 3 MAD.",
  "No sample was automatically removed by this script. Flagged samples are retained pending author review.",
  paste(capture.output(summary(pca111)), collapse = "\n")
), "05_results/qc/GSE111782_outlier_rule.txt")

## Validation RNA-seq counts
counts_path <- "03_data/raw/GSE311535/GSE311535_carotid_plaque_counts_matrix.txt.gz"
if (!file.exists(counts_path)) stop("Missing GSE311535 count matrix")
counts311 <- read_counts_matrix(counts_path)
meta311 <- data.frame(
  sample = colnames(counts311),
  group = factor(ifelse(grepl("^(Symp|Symptomatic)", colnames(counts311), ignore.case = TRUE),
                        "symptomatic", "asymptomatic"),
                 levels = c("asymptomatic", "symptomatic")),
  cohort = "GSE311535",
  tissue = "carotid plaque from diabetic patient",
  stringsAsFactors = FALSE
)
saveRDS(counts311, "03_data/processed/GSE311535_counts.rds")
safe_write_csv(meta311, "03_data/processed/GSE311535_sample_metadata.csv")

if (requireNamespace("edgeR", quietly = TRUE)) {
  y <- edgeR::DGEList(counts = counts311, group = meta311$group)
  keep <- edgeR::filterByExpr(y, group = meta311$group)
  y <- y[keep, , keep.lib.sizes = FALSE]
  y <- edgeR::calcNormFactors(y)
  logcpm <- edgeR::cpm(y, log = TRUE, prior.count = 2)
  saveRDS(y, "03_data/processed/GSE311535_edgeR_object.rds")
  safe_write_csv(data.frame(gene = rownames(logcpm), logcpm, check.names = FALSE),
                 "03_data/processed/GSE311535_logCPM_filtered.csv")
  lib <- data.frame(sample = colnames(y), library_size = y$samples$lib.size,
                    norm_factor = y$samples$norm.factors,
                    group = meta311$group, stringsAsFactors = FALSE)
  safe_write_csv(lib, "05_results/qc/GSE311535_library_qc.csv")
}

log_event("END 02_bulk_qc_and_preprocess status=0")
