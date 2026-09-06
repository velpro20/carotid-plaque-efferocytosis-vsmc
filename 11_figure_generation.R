# Purpose: generate reproducible publication-style figures from result tables.
# Inputs: QC, DEG, signature, single-cell, and validation tables under 05_results.
# Outputs: Figures 1-7 as PDF, PNG, SVG, and 300-dpi TIFF, plus figure source-data tables.
# Dependencies: ggplot2; patchwork optional for multi-panel assembly.
# Run order: after external validation and optional-module status scripts.

set.seed(20260903)
source("04_scripts/_common.R")
ensure_project_dirs()
log_event("START 11_figure_generation")

if (!requireNamespace("ggplot2", quietly = TRUE)) {
  record_error("11_figure_generation", "ggplot2 is unavailable; figures cannot be generated")
  stop("ggplot2 required")
}

figdir <- "05_results/figures"
dir.create(figdir, recursive = TRUE, showWarnings = FALSE)

save_plot <- function(plot, stem, width = 8, height = 6) {
  ggplot2::ggsave(file.path(figdir, paste0(stem, ".pdf")), plot,
                  width = width, height = height, units = "in")
  grDevices::svg(file.path(figdir, paste0(stem, ".svg")),
                 width = width, height = height, onefile = FALSE)
  print(plot)
  grDevices::dev.off()
  ggplot2::ggsave(file.path(figdir, paste0(stem, ".png")), plot,
                  width = width, height = height, units = "in", dpi = 300)
  ggplot2::ggsave(file.path(figdir, paste0(stem, ".tiff")), plot,
                  width = width, height = height, units = "in", dpi = 300,
                  compression = "lzw")
}

combine_plots <- function(a, b) {
  if (requireNamespace("patchwork", quietly = TRUE)) {
    return(a + b + patchwork::plot_layout(widths = c(1, 1)))
  }
  a
}

theme_pub <- function() {
  ggplot2::theme_classic(base_size = 10) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 11),
      axis.text.x = ggplot2::element_text(color = "black"),
      axis.text.y = ggplot2::element_text(color = "black"),
      legend.title = ggplot2::element_text(size = 9),
      legend.text = ggplot2::element_text(size = 8),
      strip.background = ggplot2::element_rect(fill = "grey92", color = NA),
      strip.text = ggplot2::element_text(face = "bold")
    )
}

## Figure 1: study design and gates
flow <- data.frame(
  x = c(1, 2.4, 3.8), y = 1,
  label = c("GSE111782\n9 symptomatic / 9 asymptomatic\nAffymetrix discovery bulk",
            "GSE311535\n6 symptomatic / 6 asymptomatic\ndiabetic RNA-seq validation",
            "GSE260657\n8 symptomatic / 7 asymptomatic\nSmart-seq2 localization"),
  fill = c("Discovery", "Validation", "Single-cell"),
  stringsAsFactors = FALSE
)
f1 <- ggplot2::ggplot(flow, ggplot2::aes(x, y)) +
  ggplot2::geom_rect(ggplot2::aes(xmin = x - 0.48, xmax = x + 0.48,
                                  ymin = y - 0.20, ymax = y + 0.20, fill = fill),
                     color = "grey20", linewidth = 0.4) +
  ggplot2::geom_segment(data = data.frame(x = c(1.52, 2.92), xend = c(1.92, 3.32), y = 1, yend = 1),
                        ggplot2::aes(x = x, xend = xend, y = y, yend = yend),
                        arrow = ggplot2::arrow(length = grid::unit(0.12, "in")), inherit.aes = FALSE) +
  ggplot2::geom_text(ggplot2::aes(label = label), lineheight = 0.95, size = 3) +
  ggplot2::annotate("text", x = 2.4, y = 1.38, label = "Public human carotid plaque evidence gates",
                    fontface = "bold", size = 4) +
  ggplot2::annotate("text", x = 2.4, y = 0.62,
                    label = "Analyses are reported as symptomatic versus asymptomatic plaques; discovery, validation, and single-cell evidence are not pooled.",
                    size = 3.1) +
  ggplot2::scale_fill_manual(values = c(Discovery = "#79A7D3", Validation = "#86B875", `Single-cell` = "#D99A5B")) +
  ggplot2::coord_cartesian(xlim = c(0.35, 4.45), ylim = c(0.45, 1.48), expand = FALSE) +
  ggplot2::theme_void() + ggplot2::theme(legend.position = "none")
save_plot(f1, "Figure_1_study_design", 8, 4.2)

## Figure 2: discovery bulk QC and DE
pca <- read.csv("05_results/qc/GSE111782_PCA.csv", check.names = FALSE)
deg <- read.csv("05_results/tables/GSE111782_DEG_complete.csv", check.names = FALSE)
deg$neglog10P <- -log10(pmax(deg$P_value, .Machine$double.xmin))
deg$status <- ifelse(deg$FDR < 0.05, "FDR < 0.05", "FDR >= 0.05")
p2a <- ggplot2::ggplot(pca, ggplot2::aes(PC1, PC2, color = group)) +
  ggplot2::geom_point(size = 2.6, alpha = 0.9) +
  ggplot2::labs(title = "GSE111782 sample PCA", x = "PC1", y = "PC2", color = "Group") +
  ggplot2::scale_color_manual(values = c(asymptomatic = "#4E79A7", symptomatic = "#E15759")) +
  theme_pub()
p2b <- ggplot2::ggplot(deg, ggplot2::aes(logFC, neglog10P, color = status)) +
  ggplot2::geom_point(alpha = 0.55, size = 0.9) +
  ggplot2::labs(title = "GSE111782 differential expression", x = "log2 fold change", y = "-log10(P value)", color = NULL) +
  ggplot2::scale_color_manual(values = c(`FDR >= 0.05` = "grey62", `FDR < 0.05` = "#D62728")) +
  theme_pub()
save_plot(p2a, "Figure_2A_discovery_PCA", 6, 4.6)
save_plot(p2b, "Figure_2B_discovery_volcano", 6, 4.6)
save_plot(combine_plots(p2a, p2b), "Figure_2_discovery_bulk", 10, 4.6)

## Figure 3: predefined tissue-level signatures
sc <- read.csv("05_results/tables/signature_scores.csv", check.names = FALSE)
sig_cols <- setdiff(names(sc), c("sample", "group", "cohort"))
long <- do.call(rbind, lapply(sig_cols, function(nm) {
  data.frame(sample = sc$sample, group = sc$group, cohort = sc$cohort,
             signature = nm, score = sc[[nm]], stringsAsFactors = FALSE)
}))
safe_write_csv(long, "05_results/tables/figure_3_signature_long.csv")
f3 <- ggplot2::ggplot(long, ggplot2::aes(group, score, color = group)) +
  ggplot2::geom_boxplot(outlier.shape = NA, linewidth = 0.35) +
  ggplot2::geom_jitter(width = 0.12, size = 1.4, alpha = 0.85) +
  ggplot2::facet_grid(cohort ~ signature, scales = "free_y") +
  ggplot2::scale_color_manual(values = c(asymptomatic = "#4E79A7", symptomatic = "#E15759")) +
  ggplot2::labs(title = "Predefined efferocytosis and VSMC program scores", x = NULL, y = "Standardized score", color = "Group") +
  theme_pub() + ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 35, hjust = 1))
save_plot(f3, "Figure_3_signature_scores", 11, 6.5)

## Figure 4: single-cell PCA and composition
ann_path <- "05_results/qc/GSE260657_cell_annotations.csv"
if (file.exists(ann_path)) {
  ann <- read.csv(ann_path, check.names = FALSE)
  ann$major_cell_type <- factor(ann$major_cell_type,
                                levels = c("macrophage", "vsmc", "endothelial", "fibroblast", "t_nk", "b_cell", "mast", "unassigned"))
  dm <- read.csv("05_results/qc/GSE260657_donor_metadata.csv", check.names = FALSE)
  ann$group <- dm$group[match(ann$file, dm$file)]
  safe_write_csv(ann[, c("file", "cell", "group", "major_cell_type", "sc_cluster", "PC1", "PC2")],
                 "05_results/tables/figure_4_single_cell_source.csv")
  p4a <- ggplot2::ggplot(ann, ggplot2::aes(PC1, PC2, color = major_cell_type)) +
    ggplot2::geom_point(size = 0.35, alpha = 0.65) +
    ggplot2::labs(title = "GSE260657 PCA-based cell atlas", x = "Cell PC1", y = "Cell PC2", color = "Cell type") +
    ggplot2::scale_color_manual(values = c(macrophage = "#4E79A7", vsmc = "#F28E2B", endothelial = "#59A14F",
                                           fibroblast = "#B07AA1", t_nk = "#E15759", b_cell = "#76B7B2",
                                           mast = "#EDC948", unassigned = "grey65"), drop = FALSE) +
    theme_pub()
  comp <- as.data.frame(table(ann$file, ann$major_cell_type), stringsAsFactors = FALSE)
  names(comp) <- c("file", "major_cell_type", "n_cells")
  comp$group <- dm$group[match(comp$file, dm$file)]
  safe_write_csv(comp, "05_results/tables/figure_4_cell_composition_source.csv")
  p4b <- ggplot2::ggplot(comp, ggplot2::aes(file, n_cells, fill = major_cell_type)) +
    ggplot2::geom_col(width = 0.8) +
    ggplot2::facet_wrap(~ group, scales = "free_x") +
    ggplot2::labs(title = "Annotated cell composition by donor", x = "Donor/sample", y = "Cells", fill = "Cell type") +
    ggplot2::scale_fill_manual(values = c(macrophage = "#4E79A7", vsmc = "#F28E2B", endothelial = "#59A14F",
                                          fibroblast = "#B07AA1", t_nk = "#E15759", b_cell = "#76B7B2",
                                          mast = "#EDC948", unassigned = "grey65"), drop = FALSE) +
    theme_pub() + ggplot2::theme(axis.text.x = ggplot2::element_blank(), axis.ticks.x = ggplot2::element_blank())
  save_plot(combine_plots(p4a, p4b), "Figure_4_single_cell_atlas", 11, 5.4)
}

## Figure 5: macrophage subclusters and efferocytosis scores
mac_sum_path <- "05_results/tables/GSE260657_macrophage_subcluster_summary.csv"
donor_prog_path <- "05_results/tables/GSE260657_donor_program_summary.csv"
if (file.exists(mac_sum_path) && file.exists(donor_prog_path)) {
  mac_sum <- read.csv(mac_sum_path, check.names = FALSE)
  donor_prog <- read.csv(donor_prog_path, check.names = FALSE)
  mac_donor <- donor_prog[donor_prog$major_cell_type == "macrophage", , drop = FALSE]
  p5a <- ggplot2::ggplot(mac_sum, ggplot2::aes(subcluster, n_cells, fill = efferocytosis_score)) +
    ggplot2::geom_col(width = 0.7) +
    ggplot2::scale_fill_gradient2(low = "#4E79A7", mid = "white", high = "#E15759", midpoint = median(mac_sum$efferocytosis_score)) +
    ggplot2::labs(title = "Macrophage program-space subclusters", x = NULL, y = "Cells", fill = "Efferocytosis\nscore") +
    theme_pub()
  p5b <- ggplot2::ggplot(mac_donor, ggplot2::aes(group, efferocytosis_score, color = group)) +
    ggplot2::geom_boxplot(outlier.shape = NA, linewidth = 0.35) +
    ggplot2::geom_jitter(width = 0.12, size = 1.8) +
    ggplot2::scale_color_manual(values = c(asymptomatic = "#4E79A7", symptomatic = "#E15759")) +
    ggplot2::labs(title = "Donor-level macrophage efferocytosis program", x = NULL, y = "Median cell score", color = "Group") +
    theme_pub()
  save_plot(combine_plots(p5a, p5b), "Figure_5_macrophage_efferocytosis", 10, 4.8)
}

## Figure 6: VSMC subclusters and optional-module gate status
vsmc_sum_path <- "05_results/tables/GSE260657_vsmc_subcluster_summary.csv"
if (file.exists(vsmc_sum_path) && file.exists(donor_prog_path)) {
  vsmc_sum <- read.csv(vsmc_sum_path, check.names = FALSE)
  donor_prog <- read.csv(donor_prog_path, check.names = FALSE)
  vsmc_donor <- donor_prog[donor_prog$major_cell_type == "vsmc", , drop = FALSE]
  vlong <- do.call(rbind, lapply(c("contractile_vsmc_score", "noncontractile_vsmc_score"), function(nm) {
    data.frame(file = vsmc_donor$file, group = vsmc_donor$group,
               program = nm, score = vsmc_donor[[nm]], stringsAsFactors = FALSE)
  }))
  p6a <- ggplot2::ggplot(vsmc_sum, ggplot2::aes(subcluster, n_cells, fill = contractile_vsmc_score)) +
    ggplot2::geom_col(width = 0.7) +
    ggplot2::scale_fill_gradient2(low = "#4E79A7", mid = "white", high = "#F28E2B", midpoint = median(vsmc_sum$contractile_vsmc_score)) +
    ggplot2::labs(title = "VSMC program-space subclusters", x = NULL, y = "Cells", fill = "Contractile\nscore") +
    theme_pub()
  p6b <- ggplot2::ggplot(vlong, ggplot2::aes(group, score, color = group)) +
    ggplot2::geom_boxplot(outlier.shape = NA, linewidth = 0.35) +
    ggplot2::geom_jitter(width = 0.12, size = 1.6) +
    ggplot2::facet_wrap(~ program, scales = "free_y") +
    ggplot2::scale_color_manual(values = c(asymptomatic = "#4E79A7", symptomatic = "#E15759")) +
    ggplot2::labs(title = "Donor-level VSMC programs", x = NULL, y = "Median cell score", color = "Group") +
    theme_pub() + ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 35, hjust = 1))
  save_plot(combine_plots(p6a, p6b), "Figure_6_vsmc_states", 10, 4.8)
}

## Figure 7: independent validation signature direction
vp <- "05_results/tables/external_validation_signature_summary.csv"
if (file.exists(vp)) {
  q <- read.csv(vp, check.names = FALSE)
  q$delta <- q$median_symptomatic - q$median_asymptomatic
  q$FDR_label <- ifelse(q$FDR < 0.05, "FDR < 0.05", "FDR >= 0.05")
  safe_write_csv(q, "05_results/tables/figure_7_validation_source.csv")
  f7 <- ggplot2::ggplot(q, ggplot2::aes(signature, delta, fill = cohort, alpha = FDR_label)) +
    ggplot2::geom_col(position = ggplot2::position_dodge(width = 0.75), width = 0.65) +
    ggplot2::geom_hline(yintercept = 0, color = "grey30", linewidth = 0.35) +
    ggplot2::scale_fill_manual(values = c(GSE111782 = "#4E79A7", GSE311535 = "#E15759")) +
    ggplot2::scale_alpha_manual(values = c(`FDR < 0.05` = 1, `FDR >= 0.05` = 0.55)) +
    ggplot2::labs(title = "Signature direction in discovery and independent validation cohorts",
                  x = NULL, y = "Median symptomatic - asymptomatic score", fill = "Cohort", alpha = "Group test") +
    theme_pub() + ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 35, hjust = 1))
  save_plot(f7, "Figure_7_external_validation", 9.5, 5)
}

## Legacy optional-module status figure: retained only for audit/editing convenience.
optional_status <- data.frame(
  module = c("WGCNA", "Cell communication", "Spatial validation", "Machine learning"),
  status = c("Skipped: discovery n < 30", "Skipped: strict annotation/database gate not met",
             "Skipped: no qualifying carotid spatial dataset", "Skipped: no validated marker set / high overfitting risk"),
  x = 1,
  y = 4:1,
  stringsAsFactors = FALSE
)
fopt <- ggplot2::ggplot(optional_status, ggplot2::aes(x, y)) +
  ggplot2::geom_rect(ggplot2::aes(xmin = x - 0.42, xmax = x + 0.42, ymin = y - 0.32, ymax = y + 0.32),
                     fill = "grey95", color = "grey35", linewidth = 0.35) +
  ggplot2::geom_text(ggplot2::aes(label = paste0(module, "\n", status)), size = 3.1, lineheight = 0.95) +
  ggplot2::annotate("text", x = 1, y = 4.65, label = "Optional modules were not used for the main conclusions",
                    fontface = "bold", size = 4) +
  ggplot2::coord_cartesian(xlim = c(0.48, 1.52), ylim = c(0.45, 4.85), expand = FALSE) +
  ggplot2::theme_void()
save_plot(fopt, "Figure_6_optional_modules", 7, 5)

writeLines(c(
  "Figure contract: quantitative panels are generated from files under 05_results/tables or 05_results/qc.",
  "Figures use symptomatic/asymptomatic terminology and do not claim causality.",
  "Exports: PDF, PNG, SVG, and 300-dpi TIFF for every generated main figure.",
  "Figure 4-6 single-cell panels are exploratory and donor-aware; cells are not treated as independent patients."
), "05_results/qc/figure_generation_notes.txt")

log_event("END 11_figure_generation status=0")
