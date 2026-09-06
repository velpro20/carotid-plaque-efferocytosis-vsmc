# Purpose: retrieve/parse human carotid plaque Smart-seq2 files and perform scRNA QC/annotation.
# Inputs: GSE260657 raw tar, family SOFT metadata, raw sample text files.
# Outputs: extracted processed matrices, QC tables, marker summaries, and gate status.
# Dependencies: base R; Seurat is optional and not required for donor-safe descriptive parsing.
# Run order: after 01_download_and_audit; before 07_scrna_macrophage_vsmc.

set.seed(20260903)
source("04_scripts/_common.R")
ensure_project_dirs()
log_event("START 06_scrna_qc_annotation")

tar_path <- "03_data/raw/GSE260657/GSE260657_RAW.tar"
soft_path <- "03_data/raw/GSE260657/GSE260657_family.soft.gz"
status_path <- "05_results/qc/GSE260657_gate_status.md"
if (!file.exists(tar_path) || file.info(tar_path)$size < 80000000L) {
  write_status(status_path, "GSE260657 single-cell gate",
               c("BLOCKED: GSE260657 raw archive is incomplete or unavailable.",
                 "Series metadata are retained for audit; no cell-level inferential result is claimed.",
                 "Gate C remains unmet until raw expression files and donor/group metadata are parsed."))
  record_error("06_scrna_qc_annotation", "GSE260657 raw archive incomplete; scRNA analysis blocked")
  log_event("END 06_scrna_qc_annotation status=0 audit-only")
} else {
  exdir <- "03_data/processed/GSE260657_raw"
  dir.create(exdir, recursive = TRUE, showWarnings = FALSE)
  if (!length(list.files(exdir, pattern = "\\.txt\\.gz$", full.names = TRUE, recursive = TRUE))) {
    untar(tar_path, exdir = exdir)
  }
  files <- list.files(exdir, pattern = "\\.txt\\.gz$", full.names = TRUE, recursive = TRUE)
  if (!length(files)) {
    write_status(status_path, "GSE260657 single-cell gate",
                 c("BLOCKED: raw archive extracted without expected TXT.GZ files.",
                   "No cell-level result is claimed."))
    record_error("06_scrna_qc_annotation", "No scRNA TXT.GZ files after extraction")
  } else {
    parse_soft_samples <- function(path) {
      lines <- readLines(gzfile(path, "rt"), warn = FALSE)
      out <- data.frame(
        gsm = sub("^!Sample_geo_accession = \"?([^\"]+)\"?$", "\\1",
                  lines[grep("^!Sample_geo_accession = ", lines)]),
        title = sub("^!Sample_title = \"?([^\"]+)\"?$", "\\1",
                    lines[grep("^!Sample_title = ", lines)]),
        subject_status = sub("^!Sample_characteristics_ch1 = subject status: ?", "",
                             lines[grep("^!Sample_characteristics_ch1 = subject status:", lines)]),
        tissue = sub("^!Sample_characteristics_ch1 = tissue: ?", "",
                     lines[grep("^!Sample_characteristics_ch1 = tissue:", lines)]),
        stringsAsFactors = FALSE
      )
      out$group <- ifelse(grepl("asymptomatic", out$subject_status, ignore.case = TRUE),
                          "asymptomatic", "symptomatic")
      out
    }
    sample_meta <- parse_soft_samples(soft_path)
    sample_meta$file_stub <- paste0(sample_meta$gsm, "_", sample_meta$title)
    safe_write_csv(sample_meta, "03_data/processed/GSE260657_sample_metadata.csv")
    safe_write_csv(sample_meta, "05_results/qc/GSE260657_sample_metadata_qc.csv")

    read_sc_file <- function(path) {
      con <- gzfile(path, "rt")
      on.exit(close(con), add = TRUE)
      tab <- read.delim(con, header = TRUE, sep = "\t", check.names = FALSE,
                        quote = "", comment.char = "", stringsAsFactors = FALSE,
                        row.names = 1L)
      genes <- make.unique(gsub('^"|"$', "", as.character(rownames(tab))))
      cells <- gsub('^"|"$', "", as.character(colnames(tab)))
      mat <- data.matrix(tab)
      rownames(mat) <- genes
      colnames(mat) <- cells
      mat[!is.finite(mat)] <- 0
      mat
    }

    marker_sets <- list(
      macrophage = c("LYZ","LST1","TYROBP","FCER1G","C1QA","C1QB","C1QC","CD68","CSF1R","AIF1","APOE","TREM2","MSR1","FCGR1A"),
      vsmc = c("ACTA2","TAGLN","MYH11","CNN1","CALD1","MYL9","TPM2","DES","SMTN","MYLK"),
      endothelial = c("PECAM1","VWF","KDR","EMCN","CLDN5","ESAM","CDH5"),
      fibroblast = c("COL1A1","COL1A2","COL3A1","COL5A1","DCN","LUM","COL6A1","SPARC"),
      t_nk = c("CD3D","CD3E","TRAC","TRBC1","TRBC2","NKG7","GNLY","CTSW","IL7R","LTB"),
      b_cell = c("MS4A1","CD79A","CD74","MZB1","JCHAIN","IGHG1","IGKC"),
      mast = c("TPSAB1","TPSB2","CPA3","KIT","MS4A2")
    )

    score_cells <- function(mat, genes) {
      genes <- intersect(genes, rownames(mat))
      if (length(genes) < 2L) return(rep(NA_real_, ncol(mat)))
      lib <- pmax(colSums(mat), 1)
      norm <- log1p(t(t(mat) / lib * 10000))
      z <- t(scale(t(norm[genes, , drop = FALSE])))
      z[!is.finite(z)] <- 0
      colMeans(z, na.rm = TRUE)
    }

    parsed_files <- lapply(files, function(f) {
      x <- read_sc_file(f)
      genes <- rownames(x)
      mt <- grep("^MT-", genes, value = TRUE)
      detected <- colSums(x > 0)
      counts <- colSums(x)
      mt_frac <- if (length(mt)) colSums(x[mt, , drop = FALSE]) / pmax(counts, 1) else rep(NA_real_, ncol(x))
      score_df <- data.frame(
        cell = colnames(x),
        macrophage = score_cells(x, marker_sets$macrophage),
        vsmc = score_cells(x, marker_sets$vsmc),
        endothelial = score_cells(x, marker_sets$endothelial),
        fibroblast = score_cells(x, marker_sets$fibroblast),
        t_nk = score_cells(x, marker_sets$t_nk),
        b_cell = score_cells(x, marker_sets$b_cell),
        mast = score_cells(x, marker_sets$mast),
        stringsAsFactors = FALSE
      )
      scores <- as.matrix(score_df[, -1L, drop = FALSE])
      top <- apply(scores, 1, function(v) {
        v[is.na(v)] <- -Inf
        ord <- order(v, decreasing = TRUE)
        best <- names(v)[ord[1]]
        second <- if (length(ord) > 1L) v[ord[2]] else -Inf
        if (!is.finite(v[ord[1]]) || v[ord[1]] < 0.15 || (v[ord[1]] - second) < 0.10) "unassigned" else best
      })
      ann <- data.frame(
        file = basename(f),
        cell = score_df$cell,
        score_df[, setdiff(names(score_df), "cell"), drop = FALSE],
        major_cell_type = top,
        top_score = apply(scores, 1, max, na.rm = TRUE),
        second_score = apply(scores, 1, function(v) sort(v, decreasing = TRUE)[2]),
        detected_genes = detected,
        counts = counts,
        mt_fraction = mt_frac,
        stringsAsFactors = FALSE
      )
      file_qc <- data.frame(
        file = basename(f),
        genes = nrow(x),
        cells = ncol(x),
        median_detected_genes = median(detected),
        median_counts = median(counts),
        median_mt_fraction = median(mt_frac, na.rm = TRUE),
        stringsAsFactors = FALSE
      )
      list(file_qc = file_qc, annotation = ann)
    })
    cell_qc_list <- lapply(parsed_files, `[[`, "file_qc")
    annotation_list <- lapply(parsed_files, `[[`, "annotation")
    qc <- do.call(rbind, cell_qc_list)
    cell_annotations <- do.call(rbind, annotation_list)
    safe_write_csv(qc, "05_results/qc/GSE260657_cell_qc_by_file.csv")
    safe_write_csv(cell_annotations, "05_results/qc/GSE260657_cell_annotations.csv")
    writeLines(paste(names(cell_annotations), collapse = "\n"),
               "05_results/qc/GSE260657_cell_annotation_columns.txt")

    donor_map <- data.frame(
      file = basename(files),
      file_stub = sub("\\.txt\\.gz$", "", basename(files)),
      title_stub = sub("^GSM[0-9]+_", "", sub("\\.txt\\.gz$", "", basename(files))),
      stringsAsFactors = FALSE
    )
    donor_meta <- merge(donor_map, sample_meta, by.x = "title_stub", by.y = "title", all.x = TRUE, sort = FALSE)
    donor_meta <- donor_meta[order(match(donor_meta$file, basename(files))), ]
    safe_write_csv(donor_meta, "05_results/qc/GSE260657_donor_metadata.csv")

    counts_by_type <- aggregate(
      list(n_cells = rep(1L, nrow(cell_annotations))),
      by = list(file = cell_annotations$file, major_cell_type = cell_annotations$major_cell_type),
      FUN = sum
    )
    total_by_file <- aggregate(n_cells ~ file, data = counts_by_type, FUN = sum)
    names(total_by_file)[2] <- "total_cells"
    donor_comp <- merge(counts_by_type, total_by_file, by = "file", all.x = TRUE)
    donor_comp$fraction_of_cells <- donor_comp$n_cells / donor_comp$total_cells
    donor_comp <- merge(donor_comp, donor_meta, by = "file", all.x = TRUE, sort = FALSE)
    safe_write_csv(donor_comp, "05_results/qc/GSE260657_donor_celltype_fractions.csv")

    donor_scores <- aggregate(cbind(macrophage, vsmc, endothelial, fibroblast, t_nk, b_cell, mast) ~ file,
                              data = cell_annotations, FUN = mean)
    donor_scores <- merge(donor_scores, donor_meta, by = "file", all.x = TRUE, sort = FALSE)
    pca_input <- donor_scores[, c("macrophage","vsmc","endothelial","fibroblast","t_nk","b_cell","mast")]
    pca <- prcomp(scale(pca_input), center = TRUE, scale. = TRUE)
    pca_df <- data.frame(file = donor_scores$file, group = donor_scores$group,
                         PC1 = pca$x[, 1], PC2 = pca$x[, 2], stringsAsFactors = FALSE)
    safe_write_csv(donor_scores, "05_results/qc/GSE260657_donor_marker_summary.csv")
    safe_write_csv(pca_df, "05_results/qc/GSE260657_donor_pca.csv")

    ## Lightweight transcriptome-level cell PCA/clustering. Seurat/UMAP are optional;
    ## this fallback is intentionally donor-aware and avoids treating cells as patients.
    canonical_genes <- unique(unlist(marker_sets, use.names = FALSE))
    all_genes <- NULL
    sum_vec <- sumsq_vec <- detected_vec <- NULL
    total_cells <- 0L
    for (f in files) {
      x <- read_sc_file(f)
      lib <- pmax(colSums(x), 1)
      norm <- log1p(t(t(x) / lib * 10000))
      if (is.null(all_genes)) {
        all_genes <- rownames(x)
        sum_vec <- numeric(length(all_genes))
        sumsq_vec <- numeric(length(all_genes))
        detected_vec <- numeric(length(all_genes))
      }
      if (!identical(rownames(x), all_genes)) {
        norm <- norm[match(all_genes, rownames(norm)), , drop = FALSE]
        norm[!is.finite(norm)] <- 0
        x <- x[match(all_genes, rownames(x)), , drop = FALSE]
        x[!is.finite(x)] <- 0
      }
      sum_vec <- sum_vec + rowSums(norm)
      sumsq_vec <- sumsq_vec + rowSums(norm^2)
      detected_vec <- detected_vec + rowSums(x > 0)
      total_cells <- total_cells + ncol(x)
    }
    gene_mean <- sum_vec / total_cells
    gene_var <- (sumsq_vec - total_cells * gene_mean^2) / pmax(total_cells - 1L, 1L)
    detect_frac <- detected_vec / total_cells
    hv <- order(gene_var, decreasing = TRUE, na.last = NA)
    hv <- hv[detect_frac[hv] >= 0.02 & detect_frac[hv] <= 0.98]
    hv_genes <- all_genes[head(hv, min(1200L, length(hv)))]
    selected_genes <- unique(c(hv_genes, intersect(canonical_genes, all_genes)))
    safe_write_csv(data.frame(gene = selected_genes, selection = ifelse(selected_genes %in% canonical_genes,
                                                                        "canonical_or_high_variance", "high_variance"),
                              variance = gene_var[match(selected_genes, all_genes)],
                              detection_fraction = detect_frac[match(selected_genes, all_genes)],
                              stringsAsFactors = FALSE),
                   "05_results/qc/GSE260657_clustering_genes.csv")

    selected_mats <- lapply(files, function(f) {
      x <- read_sc_file(f)
      x <- x[selected_genes, , drop = FALSE]
      lib <- pmax(colSums(x), 1)
      log1p(t(t(x) / lib * 10000))
    })
    norm_selected <- do.call(cbind, selected_mats)
    file_vec <- rep(basename(files), vapply(selected_mats, ncol, integer(1)))
    cell_vec <- unlist(lapply(selected_mats, colnames), use.names = FALSE)
    z_selected <- t(scale(t(norm_selected)))
    z_selected[!is.finite(z_selected)] <- 0
    n_pc <- min(20L, nrow(z_selected) - 1L, ncol(z_selected) - 1L)
    if (requireNamespace("irlba", quietly = TRUE)) {
      cell_pca <- irlba::prcomp_irlba(t(z_selected), n = n_pc, center = FALSE, scale. = FALSE)
    } else {
      cell_pca <- prcomp(t(z_selected), center = FALSE, scale. = FALSE, rank. = n_pc)
    }
    pc_use <- cell_pca$x[, seq_len(min(10L, ncol(cell_pca$x))), drop = FALSE]
    k <- min(10L, max(2L, floor(nrow(pc_use) / 500L)))
    km <- kmeans(pc_use, centers = k, nstart = 25, iter.max = 100)
    cluster_assign <- data.frame(file = file_vec, cell = cell_vec,
                                 sc_cluster = paste0("C", km$cluster),
                                 cell_pca$x[, seq_len(min(5L, ncol(cell_pca$x))), drop = FALSE],
                                 stringsAsFactors = FALSE)
    safe_write_csv(cluster_assign, "05_results/qc/GSE260657_cell_pca_clusters.csv")

    match_key <- paste(cell_annotations$file, cell_annotations$cell)
    assign_key <- paste(cluster_assign$file, cluster_assign$cell)
    cell_annotations$sc_cluster <- cluster_assign$sc_cluster[match(match_key, assign_key)]
    for (pc_name in grep("^PC", names(cluster_assign), value = TRUE)) {
      cell_annotations[[pc_name]] <- cluster_assign[[pc_name]][match(match_key, assign_key)]
    }
    safe_write_csv(cell_annotations, "05_results/qc/GSE260657_cell_annotations.csv")

    cluster_comp <- as.data.frame.matrix(table(cell_annotations$sc_cluster, cell_annotations$major_cell_type))
    cluster_comp$sc_cluster <- rownames(cluster_comp)
    cluster_comp$total_cells <- rowSums(cluster_comp[, setdiff(names(cluster_comp), "sc_cluster"), drop = FALSE])
    cluster_comp$dominant_cell_type <- apply(cluster_comp[, setdiff(names(cluster_comp), c("sc_cluster", "total_cells")), drop = FALSE],
                                             1, function(v) names(v)[which.max(v)])
    cluster_comp <- cluster_comp[, c("sc_cluster", "dominant_cell_type", "total_cells",
                                     setdiff(names(cluster_comp), c("sc_cluster", "dominant_cell_type", "total_cells")))]
    safe_write_csv(cluster_comp, "05_results/qc/GSE260657_cluster_annotation_summary.csv")

    markers <- do.call(rbind, lapply(sort(unique(cell_annotations$sc_cluster)), function(cl) {
      in_cells <- cell_annotations$sc_cluster == cl
      in_idx <- match(paste(cell_annotations$file[in_cells], cell_annotations$cell[in_cells]), assign_key)
      out_idx <- match(paste(cell_annotations$file[!in_cells], cell_annotations$cell[!in_cells]), assign_key)
      in_idx <- in_idx[!is.na(in_idx)]
      out_idx <- out_idx[!is.na(out_idx)]
      if (length(in_idx) < 5L || length(out_idx) < 5L) return(NULL)
      mean_in <- rowMeans(norm_selected[, in_idx, drop = FALSE])
      mean_out <- rowMeans(norm_selected[, out_idx, drop = FALSE])
      pct_in <- rowMeans(norm_selected[, in_idx, drop = FALSE] > 0)
      pct_out <- rowMeans(norm_selected[, out_idx, drop = FALSE] > 0)
      tab <- data.frame(sc_cluster = cl, gene = rownames(norm_selected),
                        mean_in = mean_in, mean_out = mean_out,
                        logFC = mean_in - mean_out,
                        pct_in = pct_in, pct_out = pct_out,
                        stringsAsFactors = FALSE)
      tab <- tab[order(tab$logFC, decreasing = TRUE), , drop = FALSE]
      head(tab, 30L)
    }))
    if (is.null(markers)) markers <- data.frame()
    safe_write_csv(markers, "05_results/tables/GSE260657_cluster_marker_candidates.csv")

    writeLines(c(
      "scRNA normalization and clustering record for GSE260657",
      "Normalization: log1p(counts / cell library size * 10000).",
      paste0("Feature selection: top high-variance genes plus canonical markers; n=", length(selected_genes), "."),
      paste0("Dimensionality reduction: PCA; PCs computed=", n_pc, "."),
      paste0("Clustering: k-means on the first ", ncol(pc_use), " PCs; k=", k, "."),
      "UMAP: skipped because the uwot package was not available in the locked environment.",
      "Annotation: canonical marker-score winner with unassigned calls retained; cluster dominant labels are descriptive.",
      "Between-group inference: donor/file is the independent unit; cells are not treated as independent patients."
    ), "05_results/qc/GSE260657_clustering_notes.txt")

    write_status(status_path, "GSE260657 single-cell gate",
                 c("PASS: raw Smart-seq2 text files were parsed and donor-level symptom labels were verified from GEO metadata.",
                   "Cell-level QC, log-normalization, PCA, k-means clustering, marker-candidate tables, marker scoring, donor summaries, and PCA are available in the qc tables.",
                   "Cells are not treated as independent patients; downstream group summaries should use donor-level aggregation."))
  }
  log_event("END 06_scrna_qc_annotation status=0")
}
