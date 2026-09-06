# Purpose: final technical revision analyses and figure regeneration.
# Inputs: previously generated bulk and single-cell result tables plus processed matrices.
# Outputs: fourth-revision proxy audits, single-cell specificity summaries,
#          revised main figures, supplementary dotplots, and figure QA notes.
# Dependencies: R, ggplot2; patchwork is optional for multi-panel assembly.
# Run order: after 18_review_response_sensitivity_analysis.R.

set.seed(20260904)
source("04_scripts/_common.R")
ensure_project_dirs()
log_event("START 20_final_technical_revision_analysis_and_figures")

if (!requireNamespace("ggplot2", quietly = TRUE)) {
  record_error("20_final_technical_revision_analysis_and_figures", "ggplot2 is unavailable")
  stop("ggplot2 required")
}

figdir <- "05_results/figures"
out_dir <- "05_results/tables"
qc_dir <- "05_results/qc"
dir.create(figdir, recursive = TRUE, showWarnings = FALSE)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

library(ggplot2)
has_patchwork <- requireNamespace("patchwork", quietly = TRUE)

theme_pub <- function(base_size = 8.5) {
  ggplot2::theme_classic(base_size = base_size, base_family = "Arial") +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = base_size + 1),
      plot.subtitle = ggplot2::element_text(size = base_size - 0.5),
      axis.text = ggplot2::element_text(color = "black"),
      axis.title = ggplot2::element_text(color = "black"),
      axis.line = ggplot2::element_line(linewidth = 0.35),
      axis.ticks = ggplot2::element_line(linewidth = 0.3),
      legend.title = ggplot2::element_text(size = base_size - 0.5),
      legend.text = ggplot2::element_text(size = base_size - 1),
      strip.background = ggplot2::element_rect(fill = "grey93", color = NA),
      strip.text = ggplot2::element_text(face = "bold", size = base_size - 0.5),
      panel.grid.major.y = ggplot2::element_line(color = "grey90", linewidth = 0.2),
      panel.grid.minor = ggplot2::element_blank()
    )
}

save_plot <- function(plot, stem, width = 8, height = 6, dpi = 600) {
  grDevices::cairo_pdf(file.path(figdir, paste0(stem, ".pdf")),
                       width = width, height = height, family = "Arial")
  print(plot)
  grDevices::dev.off()
  if (requireNamespace("svglite", quietly = TRUE)) {
    svglite::svglite(file.path(figdir, paste0(stem, ".svg")),
                     width = width, height = height)
  } else {
    grDevices::svg(file.path(figdir, paste0(stem, ".svg")),
                   width = width, height = height, onefile = FALSE, family = "Arial")
  }
  print(plot)
  grDevices::dev.off()
  ggplot2::ggsave(file.path(figdir, paste0(stem, ".png")), plot,
                  width = width, height = height, units = "in", dpi = dpi)
  ggplot2::ggsave(file.path(figdir, paste0(stem, ".tiff")), plot,
                  width = width, height = height, units = "in", dpi = dpi,
                  compression = "lzw")
}

combine2 <- function(a, b, widths = c(1, 1)) {
  if (has_patchwork) return(a + b + patchwork::plot_layout(widths = widths))
  a
}

combine4 <- function(a, b, c, d) {
  if (has_patchwork) {
    return((a + b) / (c + d) + patchwork::plot_layout(heights = c(1, 0.9)))
  }
  a
}

fmt_p <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  if (!is.finite(x)) return("NA")
  if (x < 0.001) return(formatC(x, format = "e", digits = 2))
  formatC(x, format = "f", digits = 3)
}

fmt_num <- function(x, digits = 3) {
  x <- suppressWarnings(as.numeric(x))
  if (!is.finite(x)) return("NA")
  formatC(x, format = "f", digits = digits)
}

label_signature <- function(x) {
  labs <- c(
    efferocytosis = "Efferocytosis-related",
    contractile_vsmc = "Contractile VSMC",
    synthetic_vsmc = "Synthetic VSMC",
    inflammatory_vsmc = "Inflammatory VSMC-associated",
    ecm_remodeling_vsmc = "ECM-remodeling/osteogenic VSMC"
  )
  out <- labs[x]
  out[is.na(out)] <- x[is.na(out)]
  unname(out)
}

read_sc_file <- function(path) {
  con <- gzfile(path, "rt")
  on.exit(close(con), add = TRUE)
  tab <- read.delim(con, header = TRUE, sep = "\t", check.names = FALSE,
                    quote = "", comment.char = "", stringsAsFactors = FALSE,
                    row.names = 1L)
  genes <- gsub('^"|"$', "", as.character(rownames(tab)))
  cells <- gsub('^"|"$', "", as.character(colnames(tab)))
  mat <- data.matrix(tab)
  rownames(mat) <- toupper(genes)
  colnames(mat) <- cells
  mat[!is.finite(mat)] <- 0
  if (anyDuplicated(rownames(mat))) {
    mat <- rowsum(mat, group = rownames(mat), reorder = FALSE)
  }
  mat
}

score_signatures <- function(mat, sets) {
  mat <- as.matrix(mat)
  rownames(mat) <- toupper(rownames(mat))
  if (anyDuplicated(rownames(mat))) mat <- rowsum(mat, group = rownames(mat), reorder = FALSE)
  z <- t(scale(t(mat)))
  z[!is.finite(z)] <- 0
  out <- sapply(sets, function(gs) {
    present <- intersect(toupper(gs), rownames(z))
    if (length(present) < 2L) return(rep(NA_real_, ncol(z)))
    colMeans(z[present, , drop = FALSE], na.rm = TRUE)
  })
  out <- as.data.frame(out, check.names = FALSE)
  out$sample <- colnames(mat)
  out[, c("sample", setdiff(names(out), "sample")), drop = FALSE]
}

partial_spearman <- function(d, x, y, covars) {
  dd <- d[, c(x, y, covars), drop = FALSE]
  dd <- dd[complete.cases(dd), , drop = FALSE]
  if (nrow(dd) <= length(covars) + 3L) {
    return(c(rho = NA_real_, P_value = NA_real_, n_samples = nrow(dd)))
  }
  rx <- rank(dd[[x]], ties.method = "average")
  ry <- rank(dd[[y]], ties.method = "average")
  rc <- as.data.frame(lapply(dd[, covars, drop = FALSE], rank, ties.method = "average"))
  fitx <- try(stats::lm(rx ~ ., data = rc), silent = TRUE)
  fity <- try(stats::lm(ry ~ ., data = rc), silent = TRUE)
  if (inherits(fitx, "try-error") || inherits(fity, "try-error")) {
    return(c(rho = NA_real_, P_value = NA_real_, n_samples = nrow(dd)))
  }
  ex <- residuals(fitx)
  ey <- residuals(fity)
  if (stats::sd(ex, na.rm = TRUE) == 0 || stats::sd(ey, na.rm = TRUE) == 0) {
    return(c(rho = NA_real_, P_value = NA_real_, n_samples = nrow(dd)))
  }
  ct <- suppressWarnings(stats::cor.test(ex, ey, method = "spearman", exact = FALSE))
  c(rho = unname(ct$estimate), P_value = ct$p.value, n_samples = nrow(dd))
}

partial_bootstrap <- function(d, x, y, covars, b = 5000L) {
  dd <- d[, c(x, y, covars), drop = FALSE]
  dd <- dd[complete.cases(dd), , drop = FALSE]
  n <- nrow(dd)
  if (n <= length(covars) + 3L) return(numeric())
  vals <- replicate(b, {
    idx <- sample.int(n, n, replace = TRUE)
    res <- suppressWarnings(try(partial_spearman(dd[idx, , drop = FALSE], x, y, covars), silent = TRUE))
    if (inherits(res, "try-error")) return(NA_real_)
    as.numeric(res["rho"])
  })
  vals[is.finite(vals)]
}

## Gene sets and proxy audits.
gene_sets <- read.csv(file.path(out_dir, "predefined_gene_sets.csv"), check.names = FALSE)
gene_sets$gene <- toupper(trimws(gene_sets$gene))
gene_sets$signature <- trimws(gene_sets$signature)
sets <- split(gene_sets$gene, gene_sets$signature)
sets <- lapply(sets, unique)

cell_proxy_sets <- list(
  macrophage_marker = c("LYZ", "LST1", "TYROBP", "FCER1G", "C1QA", "C1QB", "C1QC",
                        "CD68", "CSF1R", "AIF1", "APOE", "TREM2", "MSR1", "FCGR1A"),
  vsmc_marker = c("ACTA2", "TAGLN", "MYH11", "CNN1", "CALD1", "MYL9", "TPM2",
                  "DES", "SMTN", "MYLK"),
  endothelial_marker = c("PECAM1", "VWF", "KDR", "EMCN", "CLDN5", "ESAM", "CDH5"),
  fibroblast_marker = c("COL1A1", "COL1A2", "COL3A1", "COL5A1", "DCN", "LUM",
                        "COL6A1", "SPARC"),
  broad_inflammation_marker_nonoverlap = c("PTPRC", "CD14", "ITGAM", "ITGAX",
                                           "HLA-DRA", "HLA-DRB1", "HLA-DPA1",
                                           "HLA-DPB1", "NLRP3", "CXCL10",
                                           "CCL3", "CCL4", "CXCL2", "IRF1",
                                           "IRF7", "JUN", "FOS", "PTGS2")
)
cell_proxy_sets <- lapply(cell_proxy_sets, function(x) unique(toupper(x)))

proxy_table <- do.call(rbind, lapply(names(cell_proxy_sets), function(nm) {
  data.frame(proxy = nm, gene = cell_proxy_sets[[nm]], stringsAsFactors = FALSE)
}))
proxy_table$purpose <- ifelse(proxy_table$proxy == "broad_inflammation_marker_nonoverlap",
                              "Exploratory broad inflammation proxy excluding the primary inflammatory VSMC-associated genes",
                              "Exploratory cell-type marker-score proxy")
safe_write_csv(proxy_table, file.path(out_dir, "bulk_marker_proxy_gene_sets_fourth.csv"))

proxy_overlap <- do.call(rbind, lapply(names(cell_proxy_sets), function(proxy) {
  do.call(rbind, lapply(names(sets), function(sig) {
    inter <- intersect(cell_proxy_sets[[proxy]], sets[[sig]])
    uni <- union(cell_proxy_sets[[proxy]], sets[[sig]])
    data.frame(proxy = proxy, signature = sig,
               proxy_genes = length(cell_proxy_sets[[proxy]]),
               signature_genes = length(sets[[sig]]),
               overlap_count = length(inter),
               jaccard = ifelse(length(uni) > 0, length(inter) / length(uni), NA_real_),
               overlap_genes = paste(inter, collapse = ";"),
               stringsAsFactors = FALSE)
  }))
}))
safe_write_csv(proxy_overlap, file.path(out_dir, "bulk_marker_proxy_overlap_fourth.csv"))

## Recompute proxy scores and fourth-round partial Spearman analyses.
expr111 <- readRDS("03_data/processed/GSE111782_expression_gene.rds")
logcpm311 <- read.csv("03_data/processed/GSE311535_logCPM_filtered.csv", check.names = FALSE)
genes311 <- toupper(logcpm311$gene)
logcpm_mat <- as.matrix(logcpm311[, setdiff(names(logcpm311), "gene"), drop = FALSE])
rownames(logcpm_mat) <- genes311

proxy111 <- score_signatures(expr111, cell_proxy_sets)
proxy111$cohort <- "GSE111782"
proxy311 <- score_signatures(logcpm_mat, cell_proxy_sets)
proxy311$cohort <- "GSE311535"
proxy_scores <- rbind(proxy111, proxy311)
safe_write_csv(proxy_scores, file.path(out_dir, "bulk_cell_composition_proxy_scores_fourth.csv"))

scores <- read.csv(file.path(out_dir, "signature_scores.csv"), check.names = FALSE)
covar_sets <- list(
  macrophage_and_vsmc_proxy = c("macrophage_marker", "vsmc_marker"),
  four_celltype_proxy = c("macrophage_marker", "vsmc_marker", "endothelial_marker", "fibroblast_marker"),
  nonoverlap_broad_inflammation_proxy = c("broad_inflammation_marker_nonoverlap")
)

partial_rows <- list()
partial_boot_rows <- list()
for (cohort in unique(scores$cohort)) {
  d <- merge(scores[scores$cohort == cohort, , drop = FALSE],
             proxy_scores[proxy_scores$cohort == cohort, , drop = FALSE],
             by = c("sample", "cohort"), all.x = TRUE, sort = FALSE)
  partial_rows[[cohort]] <- do.call(rbind, lapply(names(covar_sets), function(model) {
    res <- partial_spearman(d, "efferocytosis", "inflammatory_vsmc", covar_sets[[model]])
    data.frame(cohort = cohort, model = model,
               adjusted_for = paste(covar_sets[[model]], collapse = ";"),
               rho = as.numeric(res["rho"]),
               P_value = as.numeric(res["P_value"]),
               n_samples = as.integer(res["n_samples"]),
               n_covariates = length(covar_sets[[model]]),
               note = "Exploratory rank-residual partial Spearman using marker-score proxies; small n and collinearity limit inference.",
               stringsAsFactors = FALSE)
  }))
  partial_boot_rows[[cohort]] <- do.call(rbind, lapply(names(covar_sets), function(model) {
    vals <- partial_bootstrap(d, "efferocytosis", "inflammatory_vsmc", covar_sets[[model]], b = 5000L)
    data.frame(cohort = cohort, model = model,
               bootstrap_median_rho = ifelse(length(vals), median(vals, na.rm = TRUE), NA_real_),
               bootstrap_ci_low = ifelse(length(vals), unname(stats::quantile(vals, 0.025, na.rm = TRUE)), NA_real_),
               bootstrap_ci_high = ifelse(length(vals), unname(stats::quantile(vals, 0.975, na.rm = TRUE)), NA_real_),
               bootstrap_iterations_used = length(vals),
               stringsAsFactors = FALSE)
  }))
}
partial_df <- do.call(rbind, partial_rows)
partial_df$FDR <- p.adjust(partial_df$P_value, method = "BH")
partial_boot_df <- do.call(rbind, partial_boot_rows)
partial_final <- merge(partial_df, partial_boot_df, by = c("cohort", "model"), all.x = TRUE, sort = FALSE)
safe_write_csv(partial_final, file.path(out_dir, "main_correlation_partial_spearman_proxy_adjustment_fourth.csv"))

## Proxy-score correlation and collinearity summaries.
proxy_corr_rows <- list()
vif_rows <- list()
vars_for_corr <- c("efferocytosis", "inflammatory_vsmc", names(cell_proxy_sets))
for (cohort in unique(scores$cohort)) {
  d <- merge(scores[scores$cohort == cohort, , drop = FALSE],
             proxy_scores[proxy_scores$cohort == cohort, , drop = FALSE],
             by = c("sample", "cohort"), all.x = TRUE, sort = FALSE)
  pairs <- utils::combn(vars_for_corr, 2, simplify = FALSE)
  proxy_corr_rows[[cohort]] <- do.call(rbind, lapply(pairs, function(pair) {
    dd <- d[, pair, drop = FALSE]
    dd <- dd[complete.cases(dd), , drop = FALSE]
    ct <- suppressWarnings(stats::cor.test(dd[[1]], dd[[2]], method = "spearman", exact = FALSE))
    data.frame(cohort = cohort, variable_1 = pair[1], variable_2 = pair[2],
               rho = unname(ct$estimate), P_value = ct$p.value, n_samples = nrow(dd),
               stringsAsFactors = FALSE)
  }))
  proxies <- names(cell_proxy_sets)
  vif_rows[[cohort]] <- do.call(rbind, lapply(proxies, function(target) {
    others <- setdiff(proxies, target)
    dd <- d[, c(target, others), drop = FALSE]
    dd <- dd[complete.cases(dd), , drop = FALSE]
    if (nrow(dd) <= length(others) + 2L) {
      r2 <- NA_real_
    } else {
      fit <- try(stats::lm(stats::as.formula(paste(target, "~", paste(others, collapse = "+"))), data = dd), silent = TRUE)
      r2 <- if (inherits(fit, "try-error")) NA_real_ else summary(fit)$r.squared
    }
    data.frame(cohort = cohort, proxy = target, n_samples = nrow(dd),
               r_squared_against_other_proxies = r2,
               vif_like = ifelse(is.finite(r2) && r2 < 1, 1 / (1 - r2), NA_real_),
               note = "VIF-like diagnostic for marker-score collinearity, not a formal deconvolution metric.",
               stringsAsFactors = FALSE)
  }))
}
proxy_corr <- do.call(rbind, proxy_corr_rows)
proxy_corr$FDR <- p.adjust(proxy_corr$P_value, method = "BH")
safe_write_csv(proxy_corr, file.path(out_dir, "bulk_proxy_score_correlation_matrix_fourth.csv"))
safe_write_csv(do.call(rbind, vif_rows), file.path(out_dir, "bulk_proxy_collinearity_summary_fourth.csv"))

## Single-cell marker and inflammatory VSMC-associated expression specificity.
ann_path <- file.path(qc_dir, "GSE260657_cell_annotations.csv")
dm_path <- file.path(qc_dir, "GSE260657_donor_metadata.csv")
exdir <- "03_data/processed/GSE260657_raw"
files <- if (dir.exists(exdir)) list.files(exdir, pattern = "\\.txt\\.gz$", full.names = TRUE, recursive = TRUE) else character()
ann <- if (file.exists(ann_path)) read.csv(ann_path, check.names = FALSE) else data.frame()
dm <- if (file.exists(dm_path)) read.csv(dm_path, check.names = FALSE) else data.frame()

celltype_order <- c("macrophage", "vsmc", "endothelial", "fibroblast", "t_nk", "b_cell", "mast", "unassigned")
inflam_genes <- sets$inflammatory_vsmc
marker_catalog <- data.frame(
  gene = c("ACTA2", "TAGLN", "MYH11", "CNN1", "RGS5", "MCAM",
           "LST1", "TYROBP", "FCER1G", "AIF1", "C1QA", "C1QB", "C1QC", "CD68",
           "PECAM1", "VWF", "CLDN5", "CDH5",
           "COL1A1", "COL1A2", "DCN", "LUM",
           "CD3D", "TRAC", "NKG7",
           "MS4A1", "CD79A",
           "TPSAB1", "CPA3", "KIT",
           inflam_genes),
  panel = c(rep("VSMC markers", 6),
            rep("Macrophage markers", 8),
            rep("Endothelial markers", 4),
            rep("Fibroblast markers", 4),
            rep("T/NK markers", 3),
            rep("B-cell markers", 2),
            rep("Mast-cell markers", 3),
            rep("Inflammatory VSMC-associated genes", length(inflam_genes))),
  stringsAsFactors = FALSE
)
marker_catalog$gene <- unique(toupper(marker_catalog$gene))
genes_of_interest <- unique(toupper(marker_catalog$gene))

if (length(files) && nrow(ann)) {
  expr_rows <- list()
  score_rows <- list()
  for (f in files) {
    base <- basename(f)
    ann_f <- ann[ann$file == base, , drop = FALSE]
    if (!nrow(ann_f)) next
    mat <- read_sc_file(f)
    present <- intersect(genes_of_interest, rownames(mat))
    idx <- match(ann_f$cell, colnames(mat))
    keep <- !is.na(idx)
    ann_f <- ann_f[keep, , drop = FALSE]
    idx <- idx[keep]
    if (!length(idx)) next
    mat_interest <- mat[present, idx, drop = FALSE]
    lib <- pmax(colSums(mat[, idx, drop = FALSE]), 1)
    norm <- log1p(t(t(mat_interest) / lib * 10000))
    for (gene in genes_of_interest) {
      for (ct in celltype_order) {
        cells <- which(ann_f$major_cell_type == ct)
        is_present <- gene %in% rownames(norm)
        expr_rows[[length(expr_rows) + 1L]] <- data.frame(
          file = base,
          group = if (nrow(dm)) dm$group[match(base, dm$file)] else NA_character_,
          gene = gene,
          major_cell_type = ct,
          n_cells = length(cells),
          gene_present = is_present,
          mean_log1p_cpm = if (is_present && length(cells)) mean(norm[gene, cells], na.rm = TRUE) else NA_real_,
          fraction_expressing = if (is_present && length(cells)) mean(mat_interest[gene, cells] > 0, na.rm = TRUE) else NA_real_,
          stringsAsFactors = FALSE
        )
      }
    }
    present_inflam <- intersect(inflam_genes, rownames(mat))
    if (length(present_inflam) >= 2L) {
      x <- mat[present_inflam, idx, drop = FALSE]
      lib2 <- pmax(colSums(mat[, idx, drop = FALSE]), 1)
      norm2 <- log1p(t(t(x) / lib2 * 10000))
      z <- t(scale(t(norm2)))
      z[!is.finite(z)] <- 0
      sc <- colMeans(z, na.rm = TRUE)
      score_rows[[length(score_rows) + 1L]] <- data.frame(
        file = base,
        cell = ann_f$cell,
        group = if (nrow(dm)) dm$group[match(base, dm$file)] else NA_character_,
        major_cell_type = ann_f$major_cell_type,
        inflammatory_vsmc_associated_score = sc,
        n_genes_used = length(present_inflam),
        stringsAsFactors = FALSE
      )
    }
  }
  expr_by_file <- do.call(rbind, expr_rows)
  marker_expr <- aggregate(cbind(n_cells, mean_log1p_cpm, fraction_expressing) ~ gene + major_cell_type + gene_present,
                           data = expr_by_file,
                           FUN = function(v) if (all(is.na(v))) NA_real_ else median(v, na.rm = TRUE))
  names(marker_expr)[names(marker_expr) == "n_cells"] <- "median_cells_per_sample_file"
  marker_expr$display_panel <- marker_catalog$panel[match(marker_expr$gene, marker_catalog$gene)]
  marker_expr$major_cell_type <- factor(marker_expr$major_cell_type, levels = celltype_order)
  marker_expr <- marker_expr[order(match(marker_expr$display_panel, unique(marker_catalog$panel)),
                                   match(marker_expr$gene, marker_catalog$gene),
                                   marker_expr$major_cell_type), ]
  safe_write_csv(marker_expr, file.path(out_dir, "GSE260657_marker_gene_celltype_expression_fourth.csv"))

  infl_expr <- marker_expr[marker_expr$gene %in% inflam_genes, , drop = FALSE]
  safe_write_csv(infl_expr, file.path(out_dir, "GSE260657_inflammatory_vsmc_associated_gene_celltype_expression_fourth.csv"))
  infl_summary <- do.call(rbind, lapply(inflam_genes, function(g) {
    d <- infl_expr[infl_expr$gene == g & is.finite(infl_expr$mean_log1p_cpm), , drop = FALSE]
    if (!nrow(d)) {
      return(data.frame(gene = g, dominant_cell_type_by_mean = NA_character_,
                        vsmc_mean_log1p_cpm = NA_real_, vsmc_fraction_expressing = NA_real_,
                        vsmc_mean_rank = NA_integer_, max_mean_log1p_cpm = NA_real_,
                        max_fraction_expressing = NA_real_, stringsAsFactors = FALSE))
    }
    ord <- order(d$mean_log1p_cpm, decreasing = TRUE)
    vrow <- d[d$major_cell_type == "vsmc", , drop = FALSE]
    data.frame(
      gene = g,
      dominant_cell_type_by_mean = as.character(d$major_cell_type[ord[1]]),
      vsmc_mean_log1p_cpm = ifelse(nrow(vrow), vrow$mean_log1p_cpm[1], NA_real_),
      vsmc_fraction_expressing = ifelse(nrow(vrow), vrow$fraction_expressing[1], NA_real_),
      vsmc_mean_rank = ifelse(nrow(vrow), match(which(d$major_cell_type == "vsmc"), ord), NA_integer_),
      max_mean_log1p_cpm = d$mean_log1p_cpm[ord[1]],
      max_fraction_expressing = max(d$fraction_expressing, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  }))
  safe_write_csv(infl_summary, file.path(out_dir, "GSE260657_inflammatory_vsmc_associated_gene_specificity_summary_fourth.csv"))

  score_cells <- if (length(score_rows)) do.call(rbind, score_rows) else data.frame()
  if (nrow(score_cells)) {
    safe_write_csv(score_cells, file.path(out_dir, "GSE260657_inflammatory_vsmc_associated_cell_scores_fourth.csv"))
    score_by_sample <- aggregate(inflammatory_vsmc_associated_score ~ file + group + major_cell_type,
                                 data = score_cells, FUN = median)
    count_by_sample <- aggregate(list(n_cells = rep(1L, nrow(score_cells))),
                                 by = list(file = score_cells$file, group = score_cells$group,
                                           major_cell_type = score_cells$major_cell_type),
                                 FUN = sum)
    score_by_sample <- merge(score_by_sample, count_by_sample,
                             by = c("file", "group", "major_cell_type"), all.x = TRUE, sort = FALSE)
    safe_write_csv(score_by_sample, file.path(out_dir, "GSE260657_inflammatory_vsmc_associated_score_by_sample_celltype_fourth.csv"))
    score_summary <- aggregate(inflammatory_vsmc_associated_score ~ major_cell_type,
                               data = score_by_sample, FUN = function(v) median(v, na.rm = TRUE))
    names(score_summary)[2] <- "median_sample_level_score"
    iqr_summary <- aggregate(inflammatory_vsmc_associated_score ~ major_cell_type,
                             data = score_by_sample,
                             FUN = function(v) paste0(formatC(stats::quantile(v, 0.25, na.rm = TRUE), digits = 3, format = "f"),
                                                       " to ",
                                                       formatC(stats::quantile(v, 0.75, na.rm = TRUE), digits = 3, format = "f")))
    names(iqr_summary)[2] <- "iqr_sample_level_score"
    n_summary <- aggregate(file ~ major_cell_type, data = score_by_sample, FUN = function(v) length(unique(v)))
    names(n_summary)[2] <- "n_sample_files_with_celltype"
    score_summary <- merge(score_summary, iqr_summary, by = "major_cell_type", all.x = TRUE, sort = FALSE)
    score_summary <- merge(score_summary, n_summary, by = "major_cell_type", all.x = TRUE, sort = FALSE)
    score_summary$rank_by_median_score <- rank(-score_summary$median_sample_level_score, ties.method = "min")
    safe_write_csv(score_summary, file.path(out_dir, "GSE260657_inflammatory_vsmc_associated_score_celltype_summary_fourth.csv"))
  }

  ## Data-driven reduced bulk score: retain inflammatory genes whose scRNA mean expression
  ## ranks in the top two cell types for VSMC. This is a sensitivity analysis only.
  vsmc_enriched_genes <- infl_summary$gene[is.finite(infl_summary$vsmc_mean_rank) & infl_summary$vsmc_mean_rank <= 2]
  reduced_status <- data.frame(
    criterion = "scRNA VSMC mean rank <= 2 among annotated major cell types",
    retained_genes = paste(vsmc_enriched_genes, collapse = ";"),
    n_retained_genes = length(vsmc_enriched_genes),
    note = "Sensitivity analysis only; this does not establish VSMC specificity in bulk tissue.",
    stringsAsFactors = FALSE
  )
  safe_write_csv(reduced_status, file.path(out_dir, "inflammatory_vsmc_associated_reduced_signature_status_fourth.csv"))
  if (length(vsmc_enriched_genes) >= 2L) {
    reduced_sets <- list(inflammatory_vsmc_associated_reduced = vsmc_enriched_genes)
    red111 <- score_signatures(expr111, reduced_sets)
    red111$cohort <- "GSE111782"
    red311 <- score_signatures(logcpm_mat, reduced_sets)
    red311$cohort <- "GSE311535"
    red_scores <- rbind(red111, red311)
    red_scores <- merge(red_scores, scores[, c("sample", "cohort", "group", "efferocytosis")],
                        by = c("sample", "cohort"), all.x = TRUE, sort = FALSE)
    red_corr <- do.call(rbind, lapply(split(red_scores, red_scores$cohort), function(d) {
      d <- d[complete.cases(d[, c("efferocytosis", "inflammatory_vsmc_associated_reduced")]), ]
      ct <- suppressWarnings(stats::cor.test(d$efferocytosis, d$inflammatory_vsmc_associated_reduced,
                                             method = "spearman", exact = FALSE))
      data.frame(cohort = unique(d$cohort),
                 signature_1 = "efferocytosis",
                 signature_2 = "inflammatory_vsmc_associated_reduced",
                 n_samples = nrow(d), rho = unname(ct$estimate), P_value = ct$p.value,
                 retained_genes = paste(vsmc_enriched_genes, collapse = ";"),
                 stringsAsFactors = FALSE)
    }))
    red_corr$FDR <- p.adjust(red_corr$P_value, method = "BH")
    safe_write_csv(red_corr, file.path(out_dir, "bulk_reduced_inflammatory_vsmc_associated_correlation_fourth.csv"))
  }

  ## Leave-one-gene-out sensitivity for the full 12-gene inflammatory VSMC-associated score.
  loo_gene_rows <- do.call(rbind, lapply(setdiff(inflam_genes, character()), function(drop_gene) {
    reduced <- setdiff(inflam_genes, drop_gene)
    ss <- list(inflammatory_vsmc_associated_leave_one_out = reduced)
    a <- score_signatures(expr111, ss)
    a$cohort <- "GSE111782"
    b <- score_signatures(logcpm_mat, ss)
    b$cohort <- "GSE311535"
    x <- rbind(a, b)
    x <- merge(x, scores[, c("sample", "cohort", "efferocytosis")], by = c("sample", "cohort"),
               all.x = TRUE, sort = FALSE)
    do.call(rbind, lapply(split(x, x$cohort), function(d) {
      d <- d[complete.cases(d[, c("efferocytosis", "inflammatory_vsmc_associated_leave_one_out")]), ]
      ct <- suppressWarnings(stats::cor.test(d$efferocytosis, d$inflammatory_vsmc_associated_leave_one_out,
                                             method = "spearman", exact = FALSE))
      data.frame(cohort = unique(d$cohort), dropped_gene = drop_gene,
                 n_genes_used = length(reduced), n_samples = nrow(d),
                 rho = unname(ct$estimate), P_value = ct$p.value,
                 stringsAsFactors = FALSE)
    }))
  }))
  loo_gene_rows$FDR <- p.adjust(loo_gene_rows$P_value, method = "BH")
  safe_write_csv(loo_gene_rows, file.path(out_dir, "bulk_inflammatory_vsmc_associated_leave_one_gene_out_fourth.csv"))
}

## Single-cell donor/sample audit table requested by reviewer.
if (nrow(dm) && file.exists(file.path(qc_dir, "GSE260657_cell_qc_by_file.csv")) &&
    file.exists(file.path(qc_dir, "GSE260657_donor_celltype_fractions.csv"))) {
  file_qc <- read.csv(file.path(qc_dir, "GSE260657_cell_qc_by_file.csv"), check.names = FALSE)
  comp <- read.csv(file.path(qc_dir, "GSE260657_donor_celltype_fractions.csv"), check.names = FALSE)
  wide_counts <- stats::reshape(comp[, c("file", "major_cell_type", "n_cells")],
                                idvar = "file", timevar = "major_cell_type", direction = "wide")
  names(wide_counts) <- sub("^n_cells\\.", "", names(wide_counts))
  sample_audit <- merge(dm[, c("file", "gsm", "group", "subject_status")],
                        file_qc[, c("file", "cells", "median_detected_genes", "median_counts", "median_mt_fraction")],
                        by = "file", all.x = TRUE, sort = FALSE)
  sample_audit <- merge(sample_audit, wide_counts, by = "file", all.x = TRUE, sort = FALSE)
  sample_audit$donor_id_available <- "not independently verified; sample file/GSM used as donor-sample unit"
  sample_audit <- sample_audit[, c("file", "gsm", "donor_id_available", "group", "subject_status",
                                   "cells", "median_detected_genes", "median_counts", "median_mt_fraction",
                                   "macrophage", "vsmc", "endothelial", "fibroblast", "t_nk", "b_cell", "mast", "unassigned")]
  safe_write_csv(sample_audit, file.path(out_dir, "GSE260657_sample_level_celltype_audit_fourth.csv"))
}

## Revised Figure 1: independent evidence layers.
flow <- data.frame(
  xmin = c(0.8, 0.8, 3.15, 5.5),
  xmax = c(6.8, 2.55, 4.9, 7.25),
  ymin = c(3.6, 1.35, 1.35, 1.35),
  ymax = c(4.25, 2.65, 2.65, 2.65),
  label = c(
    "Public human carotid plaque datasets",
    "Discovery bulk\nGSE111782\n9 symptomatic / 9 asymptomatic\nAffymetrix microarray",
    "Independent heterogeneous\nreplication bulk\nGSE311535\n6 symptomatic / 6 asymptomatic\nRNA-seq, diabetes-specific",
    "Single-cell localization\nGSE260657\n8 symptomatic / 7 asymptomatic\nSmart-seq2 sample files"
  ),
  fill = c("parent", "discovery", "replication", "single_cell"),
  stringsAsFactors = FALSE
)
f1 <- ggplot2::ggplot() +
  ggplot2::geom_rect(data = flow,
                     ggplot2::aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = fill),
                     color = "grey25", linewidth = 0.35) +
  ggplot2::geom_segment(data = data.frame(x = c(3.8, 3.8, 3.8, 1.675, 4.025, 6.375),
                                          xend = c(3.8, 1.675, 4.025, 1.675, 4.025, 6.375),
                                          y = c(3.6, 3.05, 3.05, 3.05, 3.05, 3.05),
                                          yend = c(3.05, 3.05, 3.05, 2.65, 2.65, 2.65)),
                       ggplot2::aes(x = x, xend = xend, y = y, yend = yend),
                       linewidth = 0.35, color = "grey35") +
  ggplot2::geom_text(data = flow, ggplot2::aes(x = (xmin + xmax) / 2, y = (ymin + ymax) / 2, label = label),
                     lineheight = 0.92, size = c(3.8, 2.8, 2.55, 2.8), fontface = c("bold", "plain", "plain", "plain")) +
  ggplot2::annotate("text", x = 3.8, y = 0.68,
                    label = "Cohorts were analyzed separately and were not pooled. The single-cell layer supports localization and specificity review only, not mechanistic support for the bulk correlation.",
                    size = 2.65, lineheight = 0.95) +
  ggplot2::scale_fill_manual(values = c(parent = "#ECECEC", discovery = "#77A6B6",
                                        replication = "#D9B15E", single_cell = "#8DBA73")) +
  ggplot2::coord_cartesian(xlim = c(0.45, 7.55), ylim = c(0.45, 4.45), expand = FALSE) +
  ggplot2::theme_void() +
  ggplot2::theme(legend.position = "none")
save_plot(f1, "Figure_1_study_design", 8.2, 4.6)

## Revised Figure 2: title and legend aligned with PCA and volcano content.
pca <- read.csv(file.path(qc_dir, "GSE111782_PCA.csv"), check.names = FALSE)
deg <- read.csv(file.path(out_dir, "GSE111782_DEG_complete.csv"), check.names = FALSE)
deg$neglog10P <- -log10(pmax(deg$P_value, .Machine$double.xmin))
deg$status <- ifelse(deg$FDR < 0.05, "FDR < 0.05", "FDR >= 0.05")
p2a <- ggplot2::ggplot(pca, ggplot2::aes(PC1, PC2, color = group)) +
  ggplot2::geom_point(size = 2.4, alpha = 0.9) +
  ggplot2::labs(title = "a  GSE111782 sample structure", x = "PC1", y = "PC2", color = "Clinical group") +
  ggplot2::scale_color_manual(values = c(asymptomatic = "#3F6FA9", symptomatic = "#C84D4D")) +
  theme_pub(8.5)
p2b <- ggplot2::ggplot(deg, ggplot2::aes(logFC, neglog10P, color = status)) +
  ggplot2::geom_point(alpha = 0.55, size = 0.65) +
  ggplot2::labs(title = "b  Symptomatic versus asymptomatic differential expression",
                x = "log2 fold change", y = "-log10(P value)", color = NULL) +
  ggplot2::scale_color_manual(values = c(`FDR >= 0.05` = "grey65", `FDR < 0.05` = "#C84D4D")) +
  theme_pub(8.5)
save_plot(p2a, "Figure_2A_discovery_PCA", 5.6, 4.3)
save_plot(p2b, "Figure_2B_discovery_volcano", 5.6, 4.3)
save_plot(combine2(p2a, p2b), "Figure_2_discovery_bulk", 10.6, 4.4)

## Revised Figure 3: main correlation, forest summary, and proxy adjustment.
corr <- read.csv(file.path(out_dir, "signature_correlations.csv"), check.names = FALSE)
boot <- read.csv(file.path(out_dir, "main_correlation_bootstrap_summary.csv"), check.names = FALSE)
main_corr <- corr[corr$signature_1 == "efferocytosis" & corr$signature_2 == "inflammatory_vsmc", ]
main_corr <- merge(main_corr, boot[, c("cohort", "bootstrap_ci_low", "bootstrap_ci_high",
                                       "loo_min_rho", "loo_max_rho")], by = "cohort", all.x = TRUE)
main_corr$cohort_label <- ifelse(main_corr$cohort == "GSE111782",
                                 "GSE111782 discovery",
                                 "GSE311535 replication")
sc <- read.csv(file.path(out_dir, "signature_scores.csv"), check.names = FALSE)
figure3_source <- sc[, c("sample", "cohort", "group", "efferocytosis", "inflammatory_vsmc")]
names(figure3_source)[names(figure3_source) == "inflammatory_vsmc"] <- "inflammatory_vsmc_associated"
safe_write_csv(figure3_source, file.path(out_dir, "figure_3_main_correlation_source_fourth.csv"))

stats_lab <- function(cohort) {
  r <- main_corr[main_corr$cohort == cohort, , drop = FALSE]
  if (!nrow(r)) return("")
  paste0("rho = ", fmt_num(r$rho), "\n95% CI ", fmt_num(r$bootstrap_ci_low), " to ",
         fmt_num(r$bootstrap_ci_high), "\nFDR = ", fmt_p(r$FDR))
}
p3a <- ggplot2::ggplot(sc[sc$cohort == "GSE111782", ],
                       ggplot2::aes(efferocytosis, inflammatory_vsmc, color = group)) +
  ggplot2::geom_point(size = 2.1, alpha = 0.9) +
  ggplot2::annotate("text", x = -Inf, y = Inf, hjust = -0.05, vjust = 1.15,
                    label = stats_lab("GSE111782"), size = 2.7) +
  ggplot2::labs(title = "a  Discovery bulk", x = "Efferocytosis-related score",
                y = "Inflammatory VSMC-associated score", color = "Clinical group") +
  ggplot2::scale_color_manual(values = c(asymptomatic = "#3F6FA9", symptomatic = "#C84D4D")) +
  theme_pub(8.2)
p3b <- ggplot2::ggplot(sc[sc$cohort == "GSE311535", ],
                       ggplot2::aes(efferocytosis, inflammatory_vsmc, color = group)) +
  ggplot2::geom_point(size = 2.1, alpha = 0.9) +
  ggplot2::annotate("text", x = -Inf, y = Inf, hjust = -0.05, vjust = 1.15,
                    label = stats_lab("GSE311535"), size = 2.7) +
  ggplot2::labs(title = "b  Independent replication bulk", x = "Efferocytosis-related score",
                y = "Inflammatory VSMC-associated score", color = "Clinical group") +
  ggplot2::scale_color_manual(values = c(asymptomatic = "#3F6FA9", symptomatic = "#C84D4D")) +
  theme_pub(8.2)
p3c <- ggplot2::ggplot(main_corr,
                       ggplot2::aes(x = rho, y = reorder(cohort_label, rho))) +
  ggplot2::geom_vline(xintercept = 0, color = "grey70", linewidth = 0.35) +
  ggplot2::geom_errorbar(ggplot2::aes(xmin = bootstrap_ci_low, xmax = bootstrap_ci_high),
                         width = 0.18, linewidth = 0.45, color = "grey35",
                         orientation = "y") +
  ggplot2::geom_point(size = 2.3, color = "#2B6A6C") +
  ggplot2::geom_text(ggplot2::aes(label = paste0("FDR ", vapply(FDR, fmt_p, character(1)))),
                     nudge_y = 0.18, size = 2.45) +
  ggplot2::scale_x_continuous(limits = c(-0.05, 1.02)) +
  ggplot2::labs(title = "c  Unadjusted Spearman correlation",
                x = "rho with bootstrap 95% CI", y = NULL) +
  theme_pub(8.2)
partial_final <- read.csv(file.path(out_dir, "main_correlation_partial_spearman_proxy_adjustment_fourth.csv"),
                          check.names = FALSE)
partial_final$model_label <- factor(partial_final$model,
                                    levels = c("macrophage_and_vsmc_proxy",
                                               "four_celltype_proxy",
                                               "nonoverlap_broad_inflammation_proxy"),
                                    labels = c("Macrophage + VSMC proxies",
                                               "Four cell-type proxies",
                                               "Non-overlap inflammation proxy"))
partial_final$cohort_label <- ifelse(partial_final$cohort == "GSE111782",
                                     "GSE111782", "GSE311535")
safe_write_csv(partial_final, file.path(out_dir, "figure_3_proxy_adjustment_source_fourth.csv"))
p3d <- ggplot2::ggplot(partial_final,
                       ggplot2::aes(x = rho, y = model_label, color = cohort_label)) +
  ggplot2::geom_vline(xintercept = 0, color = "grey75", linewidth = 0.35) +
  ggplot2::geom_point(position = ggplot2::position_dodge(width = 0.5), size = 2.1) +
  ggplot2::geom_errorbar(ggplot2::aes(xmin = bootstrap_ci_low, xmax = bootstrap_ci_high),
                         position = ggplot2::position_dodge(width = 0.5),
                         width = 0.16, linewidth = 0.4,
                         orientation = "y") +
  ggplot2::scale_color_manual(values = c(GSE111782 = "#3F6FA9", GSE311535 = "#D9A441")) +
  ggplot2::scale_x_continuous(limits = c(-1, 1)) +
  ggplot2::labs(title = "d  Exploratory marker-proxy adjustment",
                x = "Partial rho with bootstrap 95% CI", y = NULL, color = "Cohort") +
  theme_pub(8.2)
save_plot(combine4(p3a, p3b, p3c, p3d), "Figure_3_signature_scores", 11.2, 7.2)

## Supplementary signature group boxplot moved out of the main Figure 3 role.
sig_cols <- setdiff(names(sc), c("sample", "group", "cohort"))
long <- do.call(rbind, lapply(sig_cols, function(nm) {
  data.frame(sample = sc$sample, group = sc$group, cohort = sc$cohort,
             signature = label_signature(nm), score = sc[[nm]], stringsAsFactors = FALSE)
}))
safe_write_csv(long, file.path(out_dir, "supplementary_signature_score_boxplot_source_fourth.csv"))
sfig_sig <- ggplot2::ggplot(long, ggplot2::aes(group, score, color = group)) +
  ggplot2::geom_boxplot(outlier.shape = NA, linewidth = 0.35) +
  ggplot2::geom_jitter(width = 0.11, size = 1.2, alpha = 0.85) +
  ggplot2::facet_grid(cohort ~ signature, scales = "free_y") +
  ggplot2::scale_color_manual(values = c(asymptomatic = "#3F6FA9", symptomatic = "#C84D4D")) +
  ggplot2::labs(title = "Supplementary signature score group comparisons",
                x = NULL, y = "Standardized score", color = "Clinical group") +
  theme_pub(8.0) +
  ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 35, hjust = 1))
save_plot(sfig_sig, "Supplementary_Figure_1_signature_group_comparisons", 11, 6.4)

## Revised Figure 4 and supplementary dotplots.
if (nrow(ann) && nrow(dm)) {
  ann$group <- dm$group[match(ann$file, dm$file)]
  ann$major_cell_type <- factor(ann$major_cell_type, levels = celltype_order)
  p4a <- ggplot2::ggplot(ann, ggplot2::aes(PC1, PC2, color = major_cell_type)) +
    ggplot2::geom_point(size = 0.33, alpha = 0.62) +
    ggplot2::labs(title = "a  PCA-based single-cell map", x = "Cell PC1", y = "Cell PC2",
                  color = "Cell type") +
    ggplot2::scale_color_manual(values = c(macrophage = "#3F6FA9", vsmc = "#C9792C",
                                           endothelial = "#4E9C62", fibroblast = "#8E6A9E",
                                           t_nk = "#C84D4D", b_cell = "#5D9CA5",
                                           mast = "#C6A43D", unassigned = "grey67"),
                                drop = FALSE) +
    theme_pub(8.0)
  comp <- read.csv(file.path(qc_dir, "GSE260657_donor_celltype_fractions.csv"), check.names = FALSE)
  comp$major_cell_type <- factor(comp$major_cell_type, levels = celltype_order)
  comp$sample_label <- sub("_athero_human_", "_", sub("\\.txt\\.gz$", "", comp$file))
  comp$sample_label <- sub("^GSM", "G", comp$sample_label)
  comp$sample_label <- factor(comp$sample_label, levels = unique(comp$sample_label[order(comp$group, comp$file)]))
  p4b <- ggplot2::ggplot(comp, ggplot2::aes(sample_label, fraction_of_cells, fill = major_cell_type)) +
    ggplot2::geom_col(width = 0.78) +
    ggplot2::facet_wrap(~ group, scales = "free_x") +
    ggplot2::scale_y_continuous(labels = function(x) paste0(round(100 * x), "%")) +
    ggplot2::scale_fill_manual(values = c(macrophage = "#3F6FA9", vsmc = "#C9792C",
                                          endothelial = "#4E9C62", fibroblast = "#8E6A9E",
                                          t_nk = "#C84D4D", b_cell = "#5D9CA5",
                                          mast = "#C6A43D", unassigned = "grey67"),
                                drop = FALSE) +
    ggplot2::labs(title = "b  Cell-type fractions by sample file",
                  x = "Sample file", y = "Fraction of parsed cells", fill = "Cell type") +
    theme_pub(8.0) +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 55, hjust = 1, size = 5.7))
  save_plot(combine2(p4a, p4b, widths = c(1.05, 1.35)), "Figure_4_single_cell_atlas", 11, 5.2)
}

marker_expr_path <- file.path(out_dir, "GSE260657_marker_gene_celltype_expression_fourth.csv")
infl_expr_path <- file.path(out_dir, "GSE260657_inflammatory_vsmc_associated_gene_celltype_expression_fourth.csv")
if (file.exists(marker_expr_path)) {
  marker_expr <- read.csv(marker_expr_path, check.names = FALSE)
  marker_expr$major_cell_type <- factor(marker_expr$major_cell_type, levels = rev(celltype_order))
  core_marker_panels <- c("VSMC markers", "Macrophage markers", "Endothelial markers",
                          "Fibroblast markers", "T/NK markers", "B-cell markers", "Mast-cell markers")
  marker_plot_df <- marker_expr[marker_expr$display_panel %in% core_marker_panels, , drop = FALSE]
  marker_plot_df$gene <- factor(marker_plot_df$gene, levels = unique(marker_plot_df$gene))
  sfig_marker <- ggplot2::ggplot(marker_plot_df,
                                 ggplot2::aes(gene, major_cell_type,
                                              size = fraction_expressing, fill = mean_log1p_cpm)) +
    ggplot2::geom_point(shape = 21, color = "grey35", stroke = 0.18, na.rm = TRUE) +
    ggplot2::facet_grid(. ~ display_panel, scales = "free_x", space = "free_x") +
    ggplot2::scale_size_continuous(range = c(0.2, 3.5), limits = c(0, 1)) +
    ggplot2::scale_fill_gradient(low = "grey95", high = "#2B6A6C", na.value = "white") +
    ggplot2::labs(title = "Supplementary single-cell marker expression by annotated cell type",
                  x = NULL, y = "Annotated cell type", size = "Fraction expressing",
                  fill = "Median mean\nlog1p CPM") +
    theme_pub(7.3) +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 55, hjust = 1, size = 5.5),
                   panel.grid.major.y = ggplot2::element_line(color = "grey88", linewidth = 0.2))
  save_plot(sfig_marker, "Supplementary_Figure_2_single_cell_marker_dotplot", 11.5, 5.2)
}
if (file.exists(infl_expr_path)) {
  infl_expr <- read.csv(infl_expr_path, check.names = FALSE)
  infl_expr$major_cell_type <- factor(infl_expr$major_cell_type, levels = rev(celltype_order))
  infl_expr$gene <- factor(infl_expr$gene, levels = inflam_genes)
  sfig_infl <- ggplot2::ggplot(infl_expr,
                               ggplot2::aes(gene, major_cell_type,
                                            size = fraction_expressing, fill = mean_log1p_cpm)) +
    ggplot2::geom_point(shape = 21, color = "grey35", stroke = 0.2, na.rm = TRUE) +
    ggplot2::scale_size_continuous(range = c(0.2, 5), limits = c(0, 1)) +
    ggplot2::scale_fill_gradient(low = "grey96", high = "#7B4A12", na.value = "white") +
    ggplot2::labs(title = "Supplementary inflammatory VSMC-associated genes across single-cell compartments",
                  subtitle = "Expression is summarized by sample file and then shown as median cell-type values.",
                  x = NULL, y = "Annotated cell type", size = "Fraction expressing",
                  fill = "Median mean\nlog1p CPM") +
    theme_pub(8.0) +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
                   panel.grid.major.y = ggplot2::element_line(color = "grey88", linewidth = 0.2))
  save_plot(sfig_infl, "Supplementary_Figure_3_inflammatory_vsmc_associated_dotplot", 10.5, 4.9)
}

## Revised Figures 5 and 6 use descriptive program-score group wording.
mac_path <- file.path(out_dir, "GSE260657_macrophage_subclusters.csv")
mac_sum_path <- file.path(out_dir, "GSE260657_macrophage_subcluster_summary.csv")
donor_prog_path <- file.path(out_dir, "GSE260657_donor_program_summary.csv")
if (file.exists(mac_path) && file.exists(mac_sum_path) && file.exists(donor_prog_path)) {
  mac <- read.csv(mac_path, check.names = FALSE)
  mac_sum <- read.csv(mac_sum_path, check.names = FALSE)
  mac_donor <- read.csv(donor_prog_path, check.names = FALSE)
  mac_donor <- mac_donor[mac_donor$major_cell_type == "macrophage", , drop = FALSE]
  p5a <- ggplot2::ggplot(mac, ggplot2::aes(macrophage_score, efferocytosis_score, color = subcluster, shape = group)) +
    ggplot2::geom_point(size = 0.7, alpha = 0.65) +
    ggplot2::labs(title = "a  Macrophage descriptive program-score groups",
                  x = "Macrophage marker score", y = "Efferocytosis-related score",
                  color = "Descriptive group", shape = "Clinical group") +
    ggplot2::scale_color_manual(values = c(macrophage_S1 = "#2B6A6C", macrophage_S2 = "#D9A441", macrophage_S3 = "#8E6A9E")) +
    theme_pub(7.8)
  mac_comp <- as.data.frame(table(mac$file, mac$subcluster), stringsAsFactors = FALSE)
  names(mac_comp) <- c("file", "subcluster", "n_cells")
  mac_comp$group <- dm$group[match(mac_comp$file, dm$file)]
  total_mac <- aggregate(n_cells ~ file, data = mac_comp, FUN = sum)
  names(total_mac)[2] <- "total_macrophages"
  mac_comp <- merge(mac_comp, total_mac, by = "file")
  mac_comp$fraction <- mac_comp$n_cells / pmax(mac_comp$total_macrophages, 1)
  mac_comp$sample_label <- sub("_athero_human_", "_", sub("\\.txt\\.gz$", "", mac_comp$file))
  mac_comp$sample_label <- sub("^GSM", "G", mac_comp$sample_label)
  mac_comp$sample_label <- factor(mac_comp$sample_label, levels = unique(mac_comp$sample_label[order(mac_comp$group, mac_comp$file)]))
  p5b <- ggplot2::ggplot(mac_comp, ggplot2::aes(sample_label, fraction, fill = subcluster)) +
    ggplot2::geom_col(width = 0.78) +
    ggplot2::facet_wrap(~ group, scales = "free_x") +
    ggplot2::scale_y_continuous(labels = function(x) paste0(round(100 * x), "%")) +
    ggplot2::scale_fill_manual(values = c(macrophage_S1 = "#2B6A6C", macrophage_S2 = "#D9A441", macrophage_S3 = "#8E6A9E")) +
    ggplot2::labs(title = "b  Descriptive group fractions by sample file",
                  x = "Sample file", y = "Fraction of macrophages", fill = "Descriptive group") +
    theme_pub(7.8) +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 55, hjust = 1, size = 5.4))
  p5c <- ggplot2::ggplot(mac_donor, ggplot2::aes(group, efferocytosis_score, color = group)) +
    ggplot2::geom_boxplot(outlier.shape = NA, linewidth = 0.35) +
    ggplot2::geom_jitter(width = 0.11, size = 1.55) +
    ggplot2::scale_color_manual(values = c(asymptomatic = "#3F6FA9", symptomatic = "#C84D4D")) +
    ggplot2::labs(title = "c  Sample-level macrophage efferocytosis score",
                  x = NULL, y = "Median cell score", color = "Clinical group") +
    theme_pub(7.8)
  if (has_patchwork) {
    f5 <- p5a / (p5b + p5c + patchwork::plot_layout(widths = c(1.4, 0.8))) +
      patchwork::plot_layout(heights = c(1.05, 0.95))
  } else {
    f5 <- p5a
  }
  save_plot(f5, "Figure_5_macrophage_efferocytosis", 10.8, 6.2)
}

vsmc_path <- file.path(out_dir, "GSE260657_vsmc_subclusters.csv")
vsmc_sum_path <- file.path(out_dir, "GSE260657_vsmc_subcluster_summary.csv")
if (file.exists(vsmc_path) && file.exists(vsmc_sum_path) && file.exists(donor_prog_path)) {
  vsmc <- read.csv(vsmc_path, check.names = FALSE)
  vsmc_donor <- read.csv(donor_prog_path, check.names = FALSE)
  vsmc_donor <- vsmc_donor[vsmc_donor$major_cell_type == "vsmc", , drop = FALSE]
  p6a <- ggplot2::ggplot(vsmc, ggplot2::aes(contractile_vsmc_score, noncontractile_vsmc_score,
                                            color = subcluster, shape = group)) +
    ggplot2::geom_point(size = 0.75, alpha = 0.65) +
    ggplot2::labs(title = "a  VSMC descriptive program-score groups",
                  x = "Contractile VSMC score", y = "Non-contractile VSMC score",
                  color = "Descriptive group", shape = "Clinical group") +
    ggplot2::scale_color_manual(values = c(vsmc_S1 = "#2B6A6C", vsmc_S2 = "#D9A441", vsmc_S3 = "#8E6A9E")) +
    theme_pub(7.8)
  v_comp <- as.data.frame(table(vsmc$file, vsmc$subcluster), stringsAsFactors = FALSE)
  names(v_comp) <- c("file", "subcluster", "n_cells")
  v_comp$group <- dm$group[match(v_comp$file, dm$file)]
  total_v <- aggregate(n_cells ~ file, data = v_comp, FUN = sum)
  names(total_v)[2] <- "total_vsmc"
  v_comp <- merge(v_comp, total_v, by = "file")
  v_comp$fraction <- v_comp$n_cells / pmax(v_comp$total_vsmc, 1)
  v_comp$sample_label <- sub("_athero_human_", "_", sub("\\.txt\\.gz$", "", v_comp$file))
  v_comp$sample_label <- sub("^GSM", "G", v_comp$sample_label)
  v_comp$sample_label <- factor(v_comp$sample_label, levels = unique(v_comp$sample_label[order(v_comp$group, v_comp$file)]))
  p6b <- ggplot2::ggplot(v_comp, ggplot2::aes(sample_label, fraction, fill = subcluster)) +
    ggplot2::geom_col(width = 0.78) +
    ggplot2::facet_wrap(~ group, scales = "free_x") +
    ggplot2::scale_y_continuous(labels = function(x) paste0(round(100 * x), "%")) +
    ggplot2::scale_fill_manual(values = c(vsmc_S1 = "#2B6A6C", vsmc_S2 = "#D9A441", vsmc_S3 = "#8E6A9E")) +
    ggplot2::labs(title = "b  Descriptive group fractions by sample file",
                  x = "Sample file", y = "Fraction of VSMCs", fill = "Descriptive group") +
    theme_pub(7.8) +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 55, hjust = 1, size = 5.4))
  vlong <- do.call(rbind, lapply(c("contractile_vsmc_score", "noncontractile_vsmc_score"), function(nm) {
    data.frame(file = vsmc_donor$file, group = vsmc_donor$group,
               program = ifelse(nm == "contractile_vsmc_score", "Contractile", "Non-contractile"),
               score = vsmc_donor[[nm]], stringsAsFactors = FALSE)
  }))
  p6c <- ggplot2::ggplot(vlong, ggplot2::aes(group, score, color = group)) +
    ggplot2::geom_boxplot(outlier.shape = NA, linewidth = 0.35) +
    ggplot2::geom_jitter(width = 0.11, size = 1.45) +
    ggplot2::facet_wrap(~ program, scales = "free_y") +
    ggplot2::scale_color_manual(values = c(asymptomatic = "#3F6FA9", symptomatic = "#C84D4D")) +
    ggplot2::labs(title = "c  Sample-level VSMC program scores",
                  x = NULL, y = "Median cell score", color = "Clinical group") +
    theme_pub(7.8) +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 35, hjust = 1, size = 6))
  if (has_patchwork) {
    f6 <- p6a / (p6b + p6c + patchwork::plot_layout(widths = c(1.4, 1.0))) +
      patchwork::plot_layout(heights = c(1.05, 0.95))
  } else {
    f6 <- p6a
  }
  save_plot(f6, "Figure_6_vsmc_states", 10.8, 6.2)
}

## Figure 7: compact replication evidence overview.
val <- read.csv(file.path(out_dir, "external_validation_signature_summary.csv"), check.names = FALSE)
val$delta <- val$median_symptomatic - val$median_asymptomatic
val$signature_label <- factor(label_signature(val$signature),
                              levels = label_signature(c("efferocytosis", "contractile_vsmc",
                                                         "synthetic_vsmc", "inflammatory_vsmc",
                                                         "ecm_remodeling_vsmc")))
val$fdr_label <- ifelse(val$FDR < 0.05, "FDR < 0.05", "FDR >= 0.05")
safe_write_csv(val, file.path(out_dir, "figure_7_replication_source_fourth.csv"))
f7 <- ggplot2::ggplot(val, ggplot2::aes(signature_label, delta, fill = cohort, alpha = fdr_label)) +
  ggplot2::geom_hline(yintercept = 0, color = "grey35", linewidth = 0.35) +
  ggplot2::geom_col(position = ggplot2::position_dodge(width = 0.75), width = 0.65) +
  ggplot2::scale_fill_manual(values = c(GSE111782 = "#3F6FA9", GSE311535 = "#D9A441")) +
  ggplot2::scale_alpha_manual(values = c(`FDR < 0.05` = 1, `FDR >= 0.05` = 0.55)) +
  ggplot2::labs(title = "Signature score directions in discovery and replication cohorts",
                subtitle = "No sample-level group comparison reached FDR < 0.05.",
                x = NULL, y = "Median symptomatic minus asymptomatic score",
                fill = "Cohort", alpha = "Group test") +
  theme_pub(8.2) +
  ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 35, hjust = 1))
save_plot(f7, "Figure_7_replication_overview", 9.8, 5.1)

## Optional module status retained as supplemental audit figure.
optional_status <- data.frame(
  module = c("WGCNA", "Cell communication", "Spatial transcriptomics", "Machine learning"),
  status = c("Not used in main conclusions: discovery n < 30",
             "Not used: annotation/database gate not met",
             "Not used: no qualifying carotid spatial dataset",
             "Not used: no FDR-supported marker set and high overfitting risk"),
  x = 1,
  y = 4:1,
  stringsAsFactors = FALSE
)
fopt <- ggplot2::ggplot(optional_status, ggplot2::aes(x, y)) +
  ggplot2::geom_rect(ggplot2::aes(xmin = x - 0.45, xmax = x + 0.45, ymin = y - 0.33, ymax = y + 0.33),
                     fill = "grey96", color = "grey35", linewidth = 0.35) +
  ggplot2::geom_text(ggplot2::aes(label = paste0(module, "\n", status)), size = 3.05, lineheight = 0.95) +
  ggplot2::annotate("text", x = 1, y = 4.67,
                    label = "Optional analyses were not used for the main conclusions",
                    fontface = "bold", size = 4) +
  ggplot2::coord_cartesian(xlim = c(0.47, 1.53), ylim = c(0.45, 4.88), expand = FALSE) +
  ggplot2::theme_void()
save_plot(fopt, "Figure_6_optional_modules", 7.4, 5.1)

writeLines(c(
  "Fourth-revision figure and analysis QA",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")),
  "Core figure contract: the main bulk claim is an unadjusted tissue-level correlation.",
  "Figure 1 uses parallel independent evidence layers, not serial arrows.",
  "Figure 2 shows discovery sample structure and differential-expression results only.",
  "Figure 3 now shows the two main scatter plots, bootstrap CI forest summary, and exploratory proxy-adjusted partial correlations.",
  "The broad inflammation proxy used in the fourth-revision partial-correlation table excludes the 12 primary inflammatory VSMC-associated genes.",
  "Supplementary dotplots report cell-type expression of canonical markers and the 12 inflammatory VSMC-associated genes.",
  "Single-cell cell counts are descriptive; donor/sample files remain the conservative independent unit.",
  "All exports were produced by R with ggplot2 and grDevices::svg/cairo_pdf devices."
), file.path(qc_dir, "final_technical_revision_analysis_and_figures_status.md"))

log_event("END 20_final_technical_revision_analysis_and_figures status=0")
