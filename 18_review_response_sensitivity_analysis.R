# Purpose: add reviewer-requested transparency and robustness checks for the manuscript revision.
# Inputs: predefined gene sets, processed bulk matrices, signature scores, and scRNA donor QC tables.
# Outputs: gene-set overlap/mapping tables, main-correlation sensitivity tables,
#          exploratory cell-composition proxy adjustment, and scRNA donor composition summaries.
# Dependencies: base R; no interactive steps.
# Run order: after 04_signature_and_enrichment.R and 07_scrna_macrophage_vsmc.R.

set.seed(20260904)

project_root <- "D:/博士阶段/4、期刊/网药/1"
setwd(project_root)
source("04_scripts/_common.R")
ensure_project_dirs()
log_event("START 18_review_response_sensitivity_analysis")

out_dir <- "05_results/tables"
qc_dir <- "05_results/qc"

gene_sets <- read.csv(file.path(out_dir, "predefined_gene_sets.csv"), check.names = FALSE)
gene_sets$gene <- toupper(trimws(gene_sets$gene))
gene_sets$signature <- trimws(gene_sets$signature)
sets <- split(gene_sets$gene, gene_sets$signature)
sets <- lapply(sets, unique)

## Gene-set categories for audit transparency. These categories are not used to select
## results post hoc; they document the prespecified biological components.
efferocytosis_category <- data.frame(
  gene = c("MERTK","AXL","TYRO3","GAS6","PROS1","MFGE8","ITGAV","ITGB3","ITGB5",
           "CD36","STAB1","STAB2","LRP1","TIMD4","ANXA1","ANXA5","TREM2","APOE",
           "ABCA1","ABCG1","NR1H3","PPARG","MARCO","MSR1","FCGR1A","FCGR3A",
           "CTSD","CTSB","LAMP1","LAMP2"),
  module = c("recognition_receptor","recognition_receptor","recognition_receptor",
             "bridging_molecule","bridging_molecule","bridging_molecule",
             "integrin_or_scavenger_uptake","integrin_or_scavenger_uptake",
             "integrin_or_scavenger_uptake","integrin_or_scavenger_uptake",
             "integrin_or_scavenger_uptake","integrin_or_scavenger_uptake",
             "integrin_or_scavenger_uptake","integrin_or_scavenger_uptake",
             "inflammation_resolution_or_ps_binding","inflammation_resolution_or_ps_binding",
             "lipid_handling_resolution","lipid_handling_resolution",
             "lipid_handling_resolution","lipid_handling_resolution",
             "lipid_handling_resolution","lipid_handling_resolution",
             "integrin_or_scavenger_uptake","integrin_or_scavenger_uptake",
             "integrin_or_scavenger_uptake","integrin_or_scavenger_uptake",
             "lysosomal_processing","lysosomal_processing","lysosomal_processing",
             "lysosomal_processing"),
  stringsAsFactors = FALSE
)
vsmc_category <- data.frame(
  signature = c(rep("contractile_vsmc", length(sets$contractile_vsmc)),
                rep("synthetic_vsmc", length(sets$synthetic_vsmc)),
                rep("inflammatory_vsmc", length(sets$inflammatory_vsmc)),
                rep("ecm_remodeling_vsmc", length(sets$ecm_remodeling_vsmc))),
  gene = c(sets$contractile_vsmc, sets$synthetic_vsmc, sets$inflammatory_vsmc,
           sets$ecm_remodeling_vsmc),
  module = c(rep("contractile", length(sets$contractile_vsmc)),
             rep("synthetic_ecm", length(sets$synthetic_vsmc)),
             rep("inflammatory", length(sets$inflammatory_vsmc)),
             rep("ecm_osteogenic", length(sets$ecm_remodeling_vsmc))),
  stringsAsFactors = FALSE
)
gene_set_category <- merge(gene_sets, rbind(
  data.frame(signature = "efferocytosis", efferocytosis_category, stringsAsFactors = FALSE),
  vsmc_category
), by = c("signature", "gene"), all.x = TRUE, sort = FALSE)
gene_set_category$source_basis <- ifelse(
  gene_set_category$signature == "efferocytosis",
  "GO/Reactome/UniProt and efferocytosis-atherosclerosis literature audit",
  "canonical VSMC markers and plaque single-cell literature audit"
)
safe_write_csv(gene_set_category, file.path(out_dir, "gene_set_category_audit.csv"))

## Pairwise overlap/Jaccard audit.
pairs <- combn(names(sets), 2, simplify = FALSE)
overlap <- do.call(rbind, lapply(pairs, function(pair) {
  a <- sets[[pair[1]]]
  b <- sets[[pair[2]]]
  inter <- intersect(a, b)
  uni <- union(a, b)
  data.frame(
    signature_1 = pair[1],
    signature_2 = pair[2],
    n_signature_1 = length(a),
    n_signature_2 = length(b),
    overlap_count = length(inter),
    union_count = length(uni),
    jaccard = ifelse(length(uni) > 0, length(inter) / length(uni), NA_real_),
    overlap_genes = paste(inter, collapse = ";"),
    stringsAsFactors = FALSE
  )
}))
safe_write_csv(overlap, file.path(out_dir, "gene_set_overlap_jaccard.csv"))

## Platform mapping summary for each signature.
expr111 <- readRDS("03_data/processed/GSE111782_expression_gene.rds")
genes111 <- toupper(rownames(expr111))
logcpm311 <- read.csv("03_data/processed/GSE311535_logCPM_filtered.csv", check.names = FALSE)
genes311 <- toupper(logcpm311$gene)
logcpm_mat <- as.matrix(logcpm311[, setdiff(names(logcpm311), "gene"), drop = FALSE])
rownames(logcpm_mat) <- logcpm311$gene
mapping_summary <- do.call(rbind, lapply(names(sets), function(sig) {
  gs <- sets[[sig]]
  data.frame(
    cohort = c("GSE111782", "GSE311535"),
    signature = sig,
    total_genes = length(gs),
    mapped_genes = c(sum(gs %in% genes111), sum(gs %in% genes311)),
    missing_genes = c(paste(setdiff(gs, genes111), collapse = ";"),
                      paste(setdiff(gs, genes311), collapse = ";")),
    stringsAsFactors = FALSE
  )
}))
mapping_summary$mapped_fraction <- with(mapping_summary, mapped_genes / total_genes)
safe_write_csv(mapping_summary, file.path(out_dir, "gene_set_platform_mapping_summary.csv"))

## Main correlation robustness checks.
scores <- read.csv(file.path(out_dir, "signature_scores.csv"), check.names = FALSE)
main_pair <- c("efferocytosis", "inflammatory_vsmc")

bootstrap_rho <- function(x, y, b = 5000L) {
  n <- length(x)
  vals <- replicate(b, {
    idx <- sample.int(n, n, replace = TRUE)
    if (length(unique(x[idx])) < 3L || length(unique(y[idx])) < 3L) return(NA_real_)
    suppressWarnings(cor(x[idx], y[idx], method = "spearman", use = "complete.obs"))
  })
  vals[is.finite(vals)]
}

loo_rows <- list()
sens_rows <- list()
for (cohort in unique(scores$cohort)) {
  d <- scores[scores$cohort == cohort, , drop = FALSE]
  x <- d[[main_pair[1]]]
  y <- d[[main_pair[2]]]
  ct <- suppressWarnings(cor.test(x, y, method = "spearman", exact = FALSE))
  loo <- do.call(rbind, lapply(seq_len(nrow(d)), function(i) {
    cti <- suppressWarnings(cor.test(x[-i], y[-i], method = "spearman", exact = FALSE))
    data.frame(cohort = cohort, removed_sample = d$sample[i], n_remaining = nrow(d) - 1L,
               rho = unname(cti$estimate), P_value = cti$p.value, stringsAsFactors = FALSE)
  }))
  boot <- bootstrap_rho(x, y, b = 5000L)
  loo_rows[[cohort]] <- loo
  sens_rows[[cohort]] <- data.frame(
    cohort = cohort,
    signature_1 = main_pair[1],
    signature_2 = main_pair[2],
    n_samples = nrow(d),
    observed_rho = unname(ct$estimate),
    observed_P_value = ct$p.value,
    loo_min_rho = min(loo$rho, na.rm = TRUE),
    loo_median_rho = median(loo$rho, na.rm = TRUE),
    loo_max_rho = max(loo$rho, na.rm = TRUE),
    bootstrap_median_rho = median(boot, na.rm = TRUE),
    bootstrap_ci_low = unname(quantile(boot, 0.025, na.rm = TRUE)),
    bootstrap_ci_high = unname(quantile(boot, 0.975, na.rm = TRUE)),
    bootstrap_iterations_used = length(boot),
    stringsAsFactors = FALSE
  )
}
loo_df <- do.call(rbind, loo_rows)
sens_df <- do.call(rbind, sens_rows)
safe_write_csv(loo_df, file.path(out_dir, "main_correlation_leave_one_out.csv"))
safe_write_csv(sens_df, file.path(out_dir, "main_correlation_bootstrap_summary.csv"))

## Exploratory fixed-effect correlation summary. This is reported only as a compact
## descriptive synthesis, not as a replacement for cohort-specific results.
z <- atanh(pmax(pmin(sens_df$observed_rho, 0.999999), -0.999999))
se <- 1 / sqrt(sens_df$n_samples - 3)
w <- 1 / se^2
pooled_z <- sum(w * z) / sum(w)
pooled_se <- sqrt(1 / sum(w))
meta <- data.frame(
  method = "exploratory_fixed_effect_fisher_z",
  cohorts = paste(sens_df$cohort, collapse = ";"),
  pooled_rho = tanh(pooled_z),
  ci_low = tanh(pooled_z - 1.96 * pooled_se),
  ci_high = tanh(pooled_z + 1.96 * pooled_se),
  note = "Exploratory descriptive synthesis only; cohorts remain reported separately because clinical and platform differences are material.",
  stringsAsFactors = FALSE
)
safe_write_csv(meta, file.path(out_dir, "main_correlation_exploratory_meta_summary.csv"))

## Bootstrap effect-size summaries for sample-level signature group comparisons.
group_summary_path <- file.path(out_dir, "external_validation_signature_summary.csv")
if (file.exists(group_summary_path)) {
  group_tests <- read.csv(group_summary_path, check.names = FALSE)
  boot_diff <- function(a, s, b = 5000L) {
    vals <- replicate(b, median(sample(s, length(s), replace = TRUE), na.rm = TRUE) -
                        median(sample(a, length(a), replace = TRUE), na.rm = TRUE))
    vals[is.finite(vals)]
  }
  effect_rows <- do.call(rbind, lapply(split(scores, scores$cohort), function(d) {
    do.call(rbind, lapply(names(sets), function(sig) {
      a <- d[d$group == "asymptomatic", sig]
      s <- d[d$group == "symptomatic", sig]
      vals <- boot_diff(a, s, b = 5000L)
      match_row <- group_tests[group_tests$cohort == unique(d$cohort) &
                                 group_tests$signature == sig, , drop = FALSE]
      data.frame(
        cohort = unique(d$cohort),
        signature = sig,
        n_asymptomatic = length(a),
        n_symptomatic = length(s),
        median_asymptomatic = median(a, na.rm = TRUE),
        median_symptomatic = median(s, na.rm = TRUE),
        median_difference_symptomatic_minus_asymptomatic = median(s, na.rm = TRUE) - median(a, na.rm = TRUE),
        bootstrap_ci_low = unname(quantile(vals, 0.025, na.rm = TRUE)),
        bootstrap_ci_high = unname(quantile(vals, 0.975, na.rm = TRUE)),
        P_value = if (nrow(match_row)) match_row$P_value[1] else NA_real_,
        FDR = if (nrow(match_row)) match_row$FDR[1] else NA_real_,
        stringsAsFactors = FALSE
      )
    }))
  }))
  safe_write_csv(effect_rows, file.path(out_dir, "signature_group_effect_sizes_bootstrap.csv"))
}

## Efferocytosis gene contribution audit for bulk scores. The scoring method gives equal
## nominal weight to each mapped standardized gene; gene-score correlations show which
## genes track most strongly with the composite score in each cohort.
gene_contribution <- function(mat, cohort) {
  mat <- as.matrix(mat)
  rownames(mat) <- toupper(rownames(mat))
  z <- t(scale(t(mat)))
  z[!is.finite(z)] <- 0
  gs <- intersect(sets$efferocytosis, rownames(z))
  score <- colMeans(z[gs, , drop = FALSE], na.rm = TRUE)
  out <- do.call(rbind, lapply(gs, function(g) {
    ct <- suppressWarnings(cor.test(z[g, ], score, method = "spearman", exact = FALSE))
    data.frame(
      cohort = cohort,
      signature = "efferocytosis",
      gene = g,
      nominal_weight = 1 / length(gs),
      spearman_rho_with_signature_score = unname(ct$estimate),
      P_value = ct$p.value,
      mean_standardized_expression = mean(z[g, ], na.rm = TRUE),
      sd_standardized_expression = sd(z[g, ], na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  }))
  out$FDR <- p.adjust(out$P_value, method = "BH")
  out
}
gene_contrib <- rbind(
  gene_contribution(expr111, "GSE111782"),
  gene_contribution(logcpm_mat, "GSE311535")
)
safe_write_csv(gene_contrib, file.path(out_dir, "efferocytosis_gene_score_contribution_bulk.csv"))

## Exploratory composition-proxy adjustment in bulk using canonical marker scores.
cell_proxy_sets <- list(
  macrophage_marker = c("LYZ","LST1","TYROBP","FCER1G","C1QA","C1QB","C1QC","CD68","CSF1R","AIF1","APOE","TREM2","MSR1","FCGR1A"),
  vsmc_marker = c("ACTA2","TAGLN","MYH11","CNN1","CALD1","MYL9","TPM2","DES","SMTN","MYLK"),
  endothelial_marker = c("PECAM1","VWF","KDR","EMCN","CLDN5","ESAM","CDH5"),
  fibroblast_marker = c("COL1A1","COL1A2","COL3A1","COL5A1","DCN","LUM","COL6A1","SPARC"),
  broad_inflammation_marker = c("IL1B","TNF","IL6","CCL2","CCL5","CXCL8","CXCL12","NFKB1","RELA","STAT3","ICAM1","VCAM1")
)

score_signatures <- function(mat, sets) {
  mat <- as.matrix(mat)
  rownames(mat) <- toupper(rownames(mat))
  z <- t(scale(t(mat)))
  z[is.na(z)] <- 0
  out <- sapply(sets, function(gs) {
    present <- intersect(toupper(gs), rownames(z))
    if (length(present) < 2L) return(rep(NA_real_, ncol(z)))
    colMeans(z[present, , drop = FALSE], na.rm = TRUE)
  })
  out <- as.data.frame(out, check.names = FALSE)
  out$sample <- colnames(mat)
  out[, c("sample", setdiff(names(out), "sample")), drop = FALSE]
}

proxy111 <- score_signatures(expr111, cell_proxy_sets)
proxy111$cohort <- "GSE111782"
proxy311 <- score_signatures(logcpm_mat, cell_proxy_sets)
proxy311$cohort <- "GSE311535"
proxy_scores <- rbind(proxy111, proxy311)
safe_write_csv(proxy_scores, file.path(out_dir, "bulk_cell_composition_proxy_scores.csv"))

partial_spearman <- function(d, x, y, covars) {
  dd <- d[, c(x, y, covars), drop = FALSE]
  dd <- dd[complete.cases(dd), , drop = FALSE]
  if (nrow(dd) <= length(covars) + 3L) {
    return(c(rho = NA_real_, P_value = NA_real_, n_samples = nrow(dd)))
  }
  rx <- rank(dd[[x]], ties.method = "average")
  ry <- rank(dd[[y]], ties.method = "average")
  rc <- as.data.frame(lapply(dd[, covars, drop = FALSE], rank, ties.method = "average"))
  fitx <- lm(rx ~ ., data = rc)
  fity <- lm(ry ~ ., data = rc)
  ct <- suppressWarnings(cor.test(residuals(fitx), residuals(fity), method = "spearman", exact = FALSE))
  c(rho = unname(ct$estimate), P_value = ct$p.value, n_samples = nrow(dd))
}

partial_rows <- list()
for (cohort in unique(scores$cohort)) {
  d <- merge(scores[scores$cohort == cohort, , drop = FALSE],
             proxy_scores[proxy_scores$cohort == cohort, , drop = FALSE],
             by = c("sample", "cohort"), all.x = TRUE, sort = FALSE)
  covar_sets <- list(
    macrophage_and_vsmc_proxy = c("macrophage_marker", "vsmc_marker"),
    four_celltype_proxy = c("macrophage_marker", "vsmc_marker", "endothelial_marker", "fibroblast_marker"),
    inflammation_proxy = c("broad_inflammation_marker")
  )
  partial_rows[[cohort]] <- do.call(rbind, lapply(names(covar_sets), function(model) {
    res <- partial_spearman(d, "efferocytosis", "inflammatory_vsmc", covar_sets[[model]])
    data.frame(cohort = cohort, model = model, adjusted_for = paste(covar_sets[[model]], collapse = ";"),
               rho = as.numeric(res["rho"]), P_value = as.numeric(res["P_value"]),
               n_samples = as.integer(res["n_samples"]),
               note = "Exploratory rank-residual partial Spearman; small n and marker-score collinearity limit inference.",
               stringsAsFactors = FALSE)
  }))
}
partial_df <- do.call(rbind, partial_rows)
partial_df$FDR <- p.adjust(partial_df$P_value, method = "BH")
safe_write_csv(partial_df, file.path(out_dir, "main_correlation_partial_spearman_proxy_adjustment.csv"))

## scRNA donor composition summaries and QC tables for reviewer traceability.
donor_comp_path <- file.path(qc_dir, "GSE260657_donor_celltype_fractions.csv")
if (file.exists(donor_comp_path)) {
  donor_comp <- read.csv(donor_comp_path, check.names = FALSE)
  comp_summary <- aggregate(
    cbind(n_cells, fraction_of_cells) ~ group + major_cell_type,
    data = donor_comp,
    FUN = function(v) paste0("median=", signif(median(v, na.rm = TRUE), 4),
                             ";IQR=", signif(quantile(v, 0.25, na.rm = TRUE), 4),
                             "-", signif(quantile(v, 0.75, na.rm = TRUE), 4))
  )
  donor_count <- aggregate(file ~ group + major_cell_type, donor_comp, function(v) length(unique(v)))
  names(donor_count)[3] <- "n_donors_with_celltype"
  comp_summary <- merge(comp_summary, donor_count, by = c("group", "major_cell_type"), all.x = TRUE, sort = FALSE)
  safe_write_csv(comp_summary, file.path(out_dir, "GSE260657_donor_celltype_composition_group_summary.csv"))

  comp_tests <- do.call(rbind, lapply(split(donor_comp, donor_comp$major_cell_type), function(d) {
    if (length(unique(d$group)) < 2L) return(NULL)
    wt_n <- suppressWarnings(wilcox.test(n_cells ~ group, data = d, exact = FALSE))
    wt_f <- suppressWarnings(wilcox.test(fraction_of_cells ~ group, data = d, exact = FALSE))
    data.frame(
      major_cell_type = unique(d$major_cell_type),
      comparison = c("n_cells", "fraction_of_cells"),
      n_donors = length(unique(d$file)),
      P_value = c(wt_n$p.value, wt_f$p.value),
      stringsAsFactors = FALSE
    )
  }))
  if (!is.null(comp_tests) && nrow(comp_tests)) {
    comp_tests$FDR <- p.adjust(comp_tests$P_value, method = "BH")
    safe_write_csv(comp_tests, file.path(out_dir, "GSE260657_donor_celltype_composition_tests.csv"))
  }
}

## Concise reviewer-response analysis note.
note <- c(
  "# Reviewer-response sensitivity analysis",
  "",
  paste0("Run date: ", format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")),
  "",
  "Generated outputs:",
  "- 05_results/tables/gene_set_category_audit.csv",
  "- 05_results/tables/gene_set_overlap_jaccard.csv",
  "- 05_results/tables/gene_set_platform_mapping_summary.csv",
  "- 05_results/tables/main_correlation_leave_one_out.csv",
  "- 05_results/tables/main_correlation_bootstrap_summary.csv",
  "- 05_results/tables/main_correlation_exploratory_meta_summary.csv",
  "- 05_results/tables/bulk_cell_composition_proxy_scores.csv",
  "- 05_results/tables/main_correlation_partial_spearman_proxy_adjustment.csv",
  "- 05_results/tables/GSE260657_donor_celltype_composition_group_summary.csv",
  "- 05_results/tables/GSE260657_donor_celltype_composition_tests.csv",
  "",
  "Interpretation boundaries:",
  "- The main bulk correlation remains a tissue-level association in mixed plaque samples.",
  "- Partial correlations use marker-score proxies rather than measured histology or deconvolution with validated reference profiles.",
  "- Bootstrap and leave-one-out intervals quantify sensitivity but do not remove clinical heterogeneity or cell-composition confounding.",
  "- scRNA donor composition tables are descriptive and donor-level; cells are not treated as independent patients."
)
writeLines(note, file.path(qc_dir, "review_response_sensitivity_analysis_status.md"))

log_event("END 18_review_response_sensitivity_analysis status=0")
