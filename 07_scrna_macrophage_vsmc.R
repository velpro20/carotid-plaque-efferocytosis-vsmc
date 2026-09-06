# Purpose: localize macrophage and VSMC programs in parsed human carotid plaque scRNA data.
# Inputs: GSE260657 extracted TXT.GZ files and predefined gene sets.
# Outputs: cell/file-level program scores and annotation summaries when raw files exist.
# Dependencies: base R; optional Seurat is not required for descriptive scoring.
# Run order: after 06_scrna_qc_annotation.

set.seed(20260903)
source("04_scripts/_common.R")
ensure_project_dirs()
log_event("START 07_scrna_macrophage_vsmc")

exdir <- "03_data/processed/GSE260657_raw"
files <- if (dir.exists(exdir)) list.files(exdir, pattern = "\\.txt\\.gz$", full.names = TRUE, recursive = TRUE) else character()
if (!length(files)) {
  write_status("05_results/qc/GSE260657_macrophage_vsmc_status.md", "Macrophage/VSMC scRNA status",
               c("BLOCKED: no parsed scRNA expression files.",
                 "No cell-level localization or inferential group comparison is claimed."))
  record_error("07_scrna_macrophage_vsmc", "No parsed GSE260657 files")
} else {
  sets <- list(
    macrophage = c("LYZ","CTSS","FCER1G","TYROBP","LST1","CD68","C1QA","C1QB","C1QC"),
    vsmc = c("ACTA2","TAGLN","MYH11","CNN1","CALD1","MYL9","TPM2"),
    efferocytosis = c("MERTK","AXL","TYRO3","GAS6","PROS1","MFGE8","ITGAV","ITGB3","CD36",
                      "STAB1","LRP1","TIMD4","TREM2","APOE","ABCA1","ABCG1","NR1H3","MARCO","MSR1"),
    contractile_vsmc = c("ACTA2","TAGLN","MYH11","CNN1","CALD1","MYL9","TPM2","DES","PLN"),
    noncontractile_vsmc = c("COL1A1","COL3A1","FN1","VCAN","SPARC","DCN","LUM","CTGF",
                            "MMP2","IL6","CCL2","CXCL8","RUNX2","SOX9","ALPL","MMP9")
  )
  score_one <- function(x, gs) {
    lib <- pmax(colSums(x), 1)
    norm <- log1p(t(t(x) / lib * 10000))
    z <- t(scale(t(norm)))
    z[is.na(z)] <- 0
    present <- intersect(gs, rownames(z))
    if (length(present) < 2L) return(rep(NA_real_, ncol(x)))
    colMeans(z[present, , drop = FALSE])
  }
  out <- do.call(rbind, lapply(files, function(f) {
    con <- gzfile(f, "rt")
    on.exit(close(con), add = TRUE)
    tab <- read.delim(con, header = TRUE, sep = "\t", check.names = FALSE,
                      quote = "", comment.char = "", stringsAsFactors = FALSE,
                      row.names = 1L)
    genes <- make.unique(gsub('^"|"$', "", as.character(rownames(tab))))
    x <- data.matrix(tab)
    rownames(x) <- genes
    colnames(x) <- gsub('^"|"$', "", colnames(x))
    x[!is.finite(x)] <- 0
    data.frame(file = basename(f), cell = colnames(x),
               macrophage_score = score_one(x, sets$macrophage),
               vsmc_score = score_one(x, sets$vsmc),
               efferocytosis_score = score_one(x, sets$efferocytosis),
               contractile_vsmc_score = score_one(x, sets$contractile_vsmc),
               noncontractile_vsmc_score = score_one(x, sets$noncontractile_vsmc),
               stringsAsFactors = FALSE)
  }))
  safe_write_csv(out, "05_results/tables/GSE260657_cell_program_scores.csv")
  by_file <- aggregate(out[, 3:7], by = list(file = out$file), FUN = function(v) mean(v, na.rm = TRUE))
  donor_meta <- if (file.exists("05_results/qc/GSE260657_donor_metadata.csv")) {
    read.csv("05_results/qc/GSE260657_donor_metadata.csv", check.names = FALSE)
  } else data.frame()
  if (nrow(donor_meta)) {
    by_file <- merge(by_file, donor_meta[, c("file", "gsm", "group", "subject_status")],
                     by = "file", all.x = TRUE, sort = FALSE)
  }
  safe_write_csv(by_file, "05_results/tables/GSE260657_file_program_scores.csv")

  cell_ann <- if (file.exists("05_results/qc/GSE260657_cell_annotations.csv")) {
    read.csv("05_results/qc/GSE260657_cell_annotations.csv", check.names = FALSE)
  } else data.frame()
  if (nrow(cell_ann)) {
    out$major_cell_type <- cell_ann$major_cell_type[
      match(paste(out$file, out$cell), paste(cell_ann$file, cell_ann$cell))
    ]
    out$group <- if (nrow(donor_meta)) donor_meta$group[
      match(out$file, donor_meta$file)
    ] else NA_character_
    safe_write_csv(out, "05_results/tables/GSE260657_cell_program_scores.csv")

    donor_program_input <- out[out$major_cell_type %in% c("macrophage", "vsmc"), , drop = FALSE]
    donor_program <- aggregate(
      cbind(efferocytosis_score, contractile_vsmc_score, noncontractile_vsmc_score) ~ file + group + major_cell_type,
      data = donor_program_input,
      FUN = function(v) median(v, na.rm = TRUE)
    )
    cell_counts <- aggregate(list(n_cells_used = rep(1L, nrow(donor_program_input))),
                             by = list(file = donor_program_input$file,
                                       major_cell_type = donor_program_input$major_cell_type),
                             FUN = sum)
    donor_program <- merge(donor_program, cell_counts,
                           by = c("file", "major_cell_type"), all.x = TRUE, sort = FALSE)
    safe_write_csv(donor_program, "05_results/tables/GSE260657_donor_program_summary.csv")

    test_rows <- do.call(rbind, lapply(c("macrophage", "vsmc"), function(cell_type) {
      d <- out[out$major_cell_type == cell_type, , drop = FALSE]
      d <- aggregate(cbind(efferocytosis_score, contractile_vsmc_score,
                           noncontractile_vsmc_score) ~ file + group, data = d,
                     FUN = function(v) median(v, na.rm = TRUE))
      if (length(unique(d$group)) < 2L) return(NULL)
      do.call(rbind, lapply(setdiff(names(d), c("file", "group")), function(sig) {
        tt <- wilcox.test(d[[sig]] ~ d$group, exact = FALSE)
        data.frame(cell_type = cell_type, program = sig, n_donors = nrow(d),
                   P_value = tt$p.value, FDR = NA_real_,
                   stringsAsFactors = FALSE)
      }))
    }))
    if (is.null(test_rows)) test_rows <- data.frame()
    if (nrow(test_rows)) test_rows$FDR <- bh(test_rows$P_value)
    safe_write_csv(test_rows, "05_results/tables/GSE260657_donor_program_tests.csv")

    secondary_cluster <- function(cell_type, cols, k = 3L) {
      d <- out[out$major_cell_type == cell_type, , drop = FALSE]
      d <- d[complete.cases(d[, cols, drop = FALSE]), , drop = FALSE]
      if (nrow(d) < k * 20L) return(data.frame())
      m <- scale(d[, cols, drop = FALSE])
      m[!is.finite(m)] <- 0
      km <- kmeans(m, centers = k, nstart = 25, iter.max = 100)
      d$subcluster <- paste0(cell_type, "_S", km$cluster)
      center <- aggregate(d[, cols, drop = FALSE], by = list(subcluster = d$subcluster), FUN = median)
      center$n_cells <- as.integer(table(d$subcluster)[center$subcluster])
      center$dominant_program <- apply(center[, cols, drop = FALSE], 1, function(v) names(v)[which.max(v)])
      safe_write_csv(center, paste0("05_results/tables/GSE260657_", cell_type, "_subcluster_summary.csv"))
      d[, c("file", "cell", "group", "major_cell_type", "subcluster", cols), drop = FALSE]
    }
    macrophage_sub <- secondary_cluster("macrophage",
                                        c("macrophage_score", "efferocytosis_score", "noncontractile_vsmc_score"),
                                        k = 3L)
    vsmc_sub <- secondary_cluster("vsmc",
                                  c("vsmc_score", "contractile_vsmc_score", "noncontractile_vsmc_score"),
                                  k = 3L)
    safe_write_csv(macrophage_sub, "05_results/tables/GSE260657_macrophage_subclusters.csv")
    safe_write_csv(vsmc_sub, "05_results/tables/GSE260657_vsmc_subclusters.csv")
  }
  write_status("05_results/qc/GSE260657_macrophage_vsmc_status.md", "Macrophage/VSMC scRNA status",
               c("Expression files were parsed and program scores were calculated.",
                 "Macrophage and VSMC state scores are summarized at the donor/file level when canonical-marker annotations are available.",
                 "Donor-level tests are exploratory and cells are not treated as independent patients.",
                 "Program scores are associations and do not prove phenotypic conversion or causality."))
}
log_event("END 07_scrna_macrophage_vsmc status=0")
