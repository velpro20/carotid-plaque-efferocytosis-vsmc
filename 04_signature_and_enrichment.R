# Purpose: score predefined efferocytosis/VSMC signatures and run enrichment.
# Inputs: processed bulk matrices, DEG tables, gene-set definitions in 02_literature.
# Outputs: gene sets, sample scores, correlations, GO/KEGG/Reactome and ranked enrichment tables.
# Dependencies: GSVA/fgsea/clusterProfiler/ReactomePA when available; limma/edgeR.
# Run order: after 03_bulk_differential_expression.

set.seed(20260903)
source("04_scripts/_common.R")
ensure_project_dirs()
log_event("START 04_signature_and_enrichment")

sets <- list(
  efferocytosis = c("MERTK","AXL","TYRO3","GAS6","PROS1","MFGE8","ITGAV","ITGB3","ITGB5",
                    "CD36","STAB1","STAB2","LRP1","TIMD4","ANXA1","ANXA5","TREM2","APOE",
                    "ABCA1","ABCG1","NR1H3","PPARG","MARCO","MSR1","FCGR1A","FCGR3A",
                    "CTSD","CTSB","LAMP1","LAMP2"),
  contractile_vsmc = c("ACTA2","TAGLN","MYH11","CNN1","CALD1","MYL9","TPM2","DES","PLN",
                       "SYNPO2","SRF","MYLK"),
  synthetic_vsmc = c("COL1A1","COL3A1","COL5A1","FN1","VCAN","SPARC","DCN","LUM","CTGF",
                     "FGF2","MMP2","TIMP1"),
  inflammatory_vsmc = c("IL6","CCL2","CCL5","CXCL8","CXCL12","ICAM1","VCAM1","NFKB1",
                        "RELA","STAT3","TNF","IL1B"),
  ecm_remodeling_vsmc = c("RUNX2","SOX9","ALPL","BMP2","MSX2","KLF4","MMP9","MMP14",
                          "COL1A1","SPARC","SPP1","POSTN")
)
gene_set_df <- do.call(rbind, lapply(names(sets), function(nm) {
  data.frame(signature = nm, gene = sets[[nm]], stringsAsFactors = FALSE)
}))
safe_write_csv(gene_set_df, "05_results/tables/predefined_gene_sets.csv")

score_signatures <- function(mat, sets) {
  mat <- as.matrix(mat)
  z <- t(scale(t(mat)))
  z[is.na(z)] <- 0
  out <- sapply(sets, function(gs) {
    present <- intersect(gs, rownames(z))
    if (length(present) < 2L) return(rep(NA_real_, ncol(z)))
    colMeans(z[present, , drop = FALSE], na.rm = TRUE)
  })
  out <- as.data.frame(out, check.names = FALSE)
  out$sample <- colnames(mat)
  out[, c("sample", setdiff(names(out), "sample")), drop = FALSE]
}

expr111 <- readRDS("03_data/processed/GSE111782_expression_gene.rds")
scores111 <- score_signatures(expr111, sets)
meta111 <- read.csv("03_data/processed/GSE111782_sample_metadata.csv", check.names = FALSE)
scores111$group <- meta111$group[match(scores111$sample, meta111$sample)]
scores111$cohort <- "GSE111782"

logcpm_path <- "03_data/processed/GSE311535_logCPM_filtered.csv"
if (file.exists(logcpm_path)) {
  x <- read.csv(logcpm_path, check.names = FALSE)
  rownames(x) <- x$gene
  x$gene <- NULL
  logcpm <- as.matrix(x)
  scores311 <- score_signatures(logcpm, sets)
  meta311 <- read.csv("03_data/processed/GSE311535_sample_metadata.csv", check.names = FALSE)
  scores311$group <- meta311$group[match(scores311$sample, meta311$sample)]
  scores311$cohort <- "GSE311535"
} else {
  scores311 <- data.frame()
}
all_scores <- rbind(scores111, scores311)
safe_write_csv(all_scores, "05_results/tables/signature_scores.csv")

sig_names <- names(sets)
cor_results <- do.call(rbind, lapply(c("GSE111782", "GSE311535"), function(cohort) {
  d <- all_scores[all_scores$cohort == cohort, , drop = FALSE]
  if (nrow(d) < 4L) return(NULL)
  pairs <- combn(sig_names, 2, simplify = FALSE)
  do.call(rbind, lapply(pairs, function(pair) {
    ct <- suppressWarnings(cor.test(d[[pair[1]]], d[[pair[2]]], method = "spearman", exact = FALSE))
    data.frame(cohort = cohort, signature_1 = pair[1], signature_2 = pair[2],
               rho = unname(ct$estimate), P_value = ct$p.value,
               FDR = NA_real_, n_samples = nrow(d), stringsAsFactors = FALSE)
  }))
}))
if (nrow(cor_results)) {
  cor_results$FDR <- bh(cor_results$P_value)
  safe_write_csv(cor_results, "05_results/tables/signature_correlations.csv")
}

## GO/KEGG/Reactome and ranked enrichment
flatten_for_csv <- function(x) {
  x <- as.data.frame(x, check.names = FALSE, stringsAsFactors = FALSE)
  list_cols <- vapply(x, is.list, logical(1))
  if (any(list_cols)) {
    x[list_cols] <- lapply(x[list_cols], function(col) {
      vapply(col, function(value) {
        if (length(value) == 0L || all(is.na(value))) return("")
        paste(as.character(value), collapse = ";")
      }, character(1))
    })
  }
  x
}

run_enrichment <- function(deg_path, cohort) {
  if (!file.exists(deg_path)) {
    record_error("04_signature_and_enrichment",
                 paste("Missing DEG input; enrichment skipped:", deg_path))
    return(invisible(FALSE))
  }
  deg <- read.csv(deg_path, check.names = FALSE)
  genes <- as.character(deg$gene)
  names_rank <- deg$statistic
  names(names_rank) <- genes
  names_rank <- sort(names_rank[is.finite(names_rank)], decreasing = TRUE)
  sig <- unique(genes[is.finite(deg$FDR) & deg$FDR < 0.05])
  if (!length(sig)) sig <- unique(genes[order(deg$P_value, na.last = NA)][seq_len(min(100L, sum(is.finite(deg$P_value))))])
  out_dir <- file.path("05_results/tables", cohort)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  ent <- integer()
  if (requireNamespace("clusterProfiler", quietly = TRUE) && requireNamespace("org.Hs.eg.db", quietly = TRUE)) {
    conv <- tryCatch(
      AnnotationDbi::select(org.Hs.eg.db::org.Hs.eg.db,
                            keys = unique(c(sig, names(names_rank))),
                            keytype = "SYMBOL", columns = c("ENTREZID")),
      error = function(e) {
        record_error("04_signature_and_enrichment",
                     paste(cohort, "gene identifier conversion failed:", e$message))
        NULL
      }
    )
    if (is.null(conv)) conv <- data.frame()
    conv <- conv[!is.na(conv$ENTREZID), , drop = FALSE]
    ent <- unique(conv$ENTREZID[conv$SYMBOL %in% sig])
    if (length(ent) >= 3L) {
      ego <- tryCatch(clusterProfiler::enrichGO(ent, OrgDb = org.Hs.eg.db::org.Hs.eg.db,
                                                keyType = "ENTREZID", ont = "BP",
                                                pAdjustMethod = "BH", readable = TRUE),
                      error = function(e) NULL)
      if (!is.null(ego)) {
        safe_write_csv(flatten_for_csv(ego), file.path(out_dir, "GO_BP_enrichment.csv"))
      } else {
        record_error("04_signature_and_enrichment",
                     paste(cohort, "GO enrichment returned no result"))
      }
      old_timeout <- getOption("timeout")
      options(timeout = min(old_timeout, 20))
      ekegg <- tryCatch(
        clusterProfiler::enrichKEGG(ent, organism = "hsa", pAdjustMethod = "BH"),
        error = function(e) {
          record_error("04_signature_and_enrichment",
                       paste(cohort, "KEGG enrichment unavailable:", e$message))
          NULL
        }
      )
      options(timeout = old_timeout)
      if (!is.null(ekegg)) {
        safe_write_csv(flatten_for_csv(ekegg), file.path(out_dir, "KEGG_enrichment.csv"))
      }
    }
  }
  if (requireNamespace("ReactomePA", quietly = TRUE) && length(ent) >= 3L) {
    er <- tryCatch(
      ReactomePA::enrichPathway(gene = ent, organism = "human",
                                pAdjustMethod = "BH", readable = TRUE),
      error = function(e) {
        record_error("04_signature_and_enrichment",
                     paste(cohort, "Reactome enrichment unavailable:", e$message))
        NULL
      }
    )
    if (!is.null(er)) {
      safe_write_csv(flatten_for_csv(er), file.path(out_dir, "Reactome_enrichment.csv"))
    }
  }
  if (requireNamespace("fgsea", quietly = TRUE)) {
    pathways <- sets
    fr <- tryCatch(
      fgsea::fgsea(pathways = pathways, stats = names_rank, minSize = 2, maxSize = 500),
      error = function(e) {
        record_error("04_signature_and_enrichment",
                     paste(cohort, "ranked signature enrichment failed:", e$message))
        NULL
      }
    )
    if (!is.null(fr)) {
      fr$padj <- p.adjust(fr$pval, method = "BH")
      safe_write_csv(flatten_for_csv(fr), file.path(out_dir, "ranked_signature_enrichment.csv"))
    }
  }
  invisible(TRUE)
}
run_enrichment("05_results/tables/GSE111782_DEG_complete.csv", "GSE111782")
run_enrichment("05_results/tables/GSE311535_DEG_complete.csv", "GSE311535")

log_event("END 04_signature_and_enrichment status=0")
