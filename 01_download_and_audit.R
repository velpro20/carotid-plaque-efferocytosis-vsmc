# Purpose: audit public accessions, verify local files, and preserve provenance.
# Inputs: GEO metadata snapshots and downloaded files under 03_data/raw.
# Outputs: dataset_audit.csv, file_hashes.csv, accession audit notes.
# Dependencies: base R; optional GEOquery for annotation retrieval.
# Run order: after 00_preflight and before matrix preprocessing.

set.seed(20260903)
source("04_scripts/_common.R")
ensure_project_dirs()
log_event("START 01_download_and_audit")

audit <- data.frame(
  accession = c("GSE111782", "GSE311535", "GSE260657", "GSE210152", "GSE120521",
                "GSE118481", "GSE270496", "GSE246315", "GSE245373", "GSE234077"),
  dataset_title = c(
    "Expression data for post-bifurcation internal carotid atheroma",
    "RNA-seq of human atherosclerotic carotid plaque tissue from diabetic patients",
    "A smooth muscle cell gene-regulatory network critical for the development of advanced-stage and symptomatic atherosclerosis [human]",
    "Single cell immune landscape of human atherosclerosis",
    "RNA-seq of stable and unstable section of human atherosclerotic plaques",
    "Gene array of laser capture microdissectioned human diabetic vs non-diabetic plaque macrophages",
    "Multi-omic Landscape of Extracellular Vesicles in Human Carotid Atherosclerotic Plaque",
    "Decoding the immune checkpoint signatures in human atherosclerosis",
    "Mice are not men: scRNA-sequencing of the human atherosclerotic plaque",
    "Human femoral atheroma exhibit inflammation-resolving myeloid and lymphoid bias compared with carotid atheroma"
  ),
  publication = c(
    "Sedgewick et al.; source publication linked from GEO",
    "Woods et al.; source publication linked from GEO",
    "Narayanan et al.; source publication linked from GEO",
    "38362263 source publication",
    "31339449 source publication",
    "source publication not indexed in GEO summary",
    "Raju et al.",
    "39613875 source publication",
    "39041203 source publication",
    "37471165 source publication"
  ),
  PMID = c("30335165", "41377472", "38639096", "38362263", "31339449", NA, "40438929",
          "39613875", "39041203", "37471165"),
  DOI = c(NA, NA, NA, NA, NA, NA, "10.1161/ATVBAHA.124.322324",
          NA, NA, NA),
  species = c("Homo sapiens", "Homo sapiens", "Homo sapiens", "Homo sapiens",
              "Homo sapiens", "Homo sapiens", "Homo sapiens", "Homo sapiens",
              "Homo sapiens; Mus musculus", "Homo sapiens"),
  tissue = c("post-bifurcation internal carotid plaque", "carotid plaque",
             "human carotid plaque scRNA-seq", "human intraplaque immune cells",
             "carotid plaque regions", "carotid plaque macrophage-enriched regions",
             "carotid plaque and marginal zone EVs", "human carotid plaque scRNA-seq",
             "human atherosclerotic plaque immune cells", "carotid and femoral atheroma"),
  platform = c("GPL571 Affymetrix HG-U133A 2.0", "GPL16791 Illumina RNA-seq",
               "GPL21290 Smart-seq2", "GPL20301 H5AD/scRNA-seq", "GPL16791 RNA-seq",
               "GPL10558 Illumina bead array", "GPL18573 small-RNA sequencing",
               "GPL24676 scRNA-seq", "GPL24676 scRNA-seq", "GPL24676 scRNA-seq"),
  assay_type = c("bulk microarray", "bulk RNA-seq counts", "single-cell RNA-seq",
                 "single-cell RNA-seq", "bulk RNA-seq", "bulk macrophage array",
                 "EV miRNA/proteomics", "single-cell RNA-seq", "single-cell RNA-seq",
                 "single-cell RNA-seq"),
  group_definition = c("symptomatic versus asymptomatic", "symptomatic versus asymptomatic in diabetic patients",
                       "asymptomatic and symptomatic carotid plaques", "clinical plaque immune atlas; group detail requires source verification",
                       "stable versus unstable regions within symptomatic plaques", "diabetic versus non-diabetic; symptom labels also present",
                       "symptomatic versus asymptomatic with plaque versus marginal zones",
                       "diabetes/intervention-related plaque immune checkpoints",
                       "human plaque immune-cell comparison; clinical validation",
                       "carotid versus femoral tissue"),
  group_sample_size = c("9/9", "6/6", "15 human samples; cell counts require raw parsing",
                        "6 patient samples", "4/4 regions", "24 samples", "16 symptomatic/13 asymptomatic patients",
                        "12 samples", "human plaque sample number requires source verification", "carotid samples pooled in metadata"),
  available_clinical_variables = c("symptom status; stenosis range in series metadata",
                                   "symptom status; diabetes; insulin/sex require source metadata",
                                   "symptom status; donor/sample identifiers require raw metadata",
                                   "patient IDs; clinical details require source paper",
                                   "region stability label; all from symptomatic patients",
                                   "diabetes and symptom labels",
                                   "symptom status; plaque/marginal zone",
                                   "diabetes and lipid-lowering context",
                                   "species and plaque context",
                                   "vascular bed"),
  source_url = paste0("https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=",
                      c("GSE111782", "GSE311535", "GSE260657", "GSE210152", "GSE120521",
                        "GSE118481", "GSE270496", "GSE246315", "GSE245373", "GSE234077")),
  data_download_url = c(
    "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE111nnn/GSE111782/",
    "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE311nnn/GSE311535/",
    "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE260nnn/GSE260657/",
    "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE210nnn/GSE210152/",
    "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE120nnn/GSE120521/",
    "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE118nnn/GSE118481/",
    "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE270nnn/GSE270496/",
    "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE246nnn/GSE246315/",
    "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE245nnn/GSE245373/",
    "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE234nnn/GSE234077/"
  ),
  included_or_excluded = c("included", "included", "included_pending_raw_check", "audit_only",
                           "excluded_primary", "audit_only", "audit_only", "audit_only",
                           "audit_only", "audit_only"),
  intended_role = c("discovery bulk", "independent bulk validation", "single-cell localization",
                    "contextual immune atlas", "pathology-region context", "diabetes macrophage context",
                    "EV/cell communication context", "immune checkpoint context",
                    "species/immune context", "vascular-bed context"),
  exclusion_reason = c(NA, NA, "C gate pending raw file and donor metadata verification",
                       "immune-focused and VSMC localization not assured",
                       "no symptomatic/asymptomatic comparison; stable/unstable region only",
                       "not a primary symptomatic/asymptomatic whole-plaque cohort",
                       "not a primary bulk transcriptome cohort",
                       "intervention/diabetes context not comparable",
                       "mixed species and immune-focused",
                       "non-carotid comparison and pooled metadata"),
  limitations = c("array platform; mixed tissue; small cohort",
                  "diabetic cohort; small cohort; RNA-seq platform",
                  "Smart-seq2 sampling; metadata/raw parsing pending",
                  "immune-cell-focused; VSMC availability uncertain",
                  "all samples from symptomatic patients; region labels differ",
                  "LCM macrophage-enriched regions and diabetes confounding",
                  "EV assay rather than whole-plaque transcriptome",
                  "intervention/metabolic context",
                  "mixed species and clinical groups",
                  "vascular-bed difference"),
  verification_status = c("GEO metadata verified", "GEO metadata verified", "GEO metadata verified; files pending",
                          "GEO metadata verified", "GEO metadata verified", "GEO metadata verified",
                          "GEO metadata verified", "GEO metadata verified", "GEO metadata verified",
                          "GEO metadata verified"),
  stringsAsFactors = FALSE
)
safe_write_csv(audit, "03_data/metadata/dataset_audit.csv")

all_rel_files <- list.files("03_data/raw", recursive = TRUE, full.names = FALSE)
all_rel_files <- all_rel_files[!file.info(file.path("03_data/raw", all_rel_files))$isdir %in% TRUE]
all_files <- file.path("03_data/raw", all_rel_files)
hash_cmd <- function(path) {
  if (.Platform$OS.type == "windows") {
    native_path <- normalizePath(path, winslash = "\\", mustWork = FALSE)
    out <- tryCatch(
      system2("powershell.exe", c("-NoProfile", "-Command",
                                  sprintf("(Get-FileHash -Algorithm SHA256 -LiteralPath '%s').Hash", native_path)),
              stdout = TRUE, stderr = FALSE),
      error = function(e) character()
    )
    out <- iconv(out, from = "", to = "UTF-8", sub = "")
    val <- out[grepl("^[0-9A-Fa-f]{64}$", trimws(out))]
    if (length(val)) {
      trimws(val[1])
    } else {
      out <- tryCatch(
        system2("certutil", c("-hashfile", native_path, "SHA256"),
                stdout = TRUE, stderr = FALSE),
        error = function(e) character()
      )
      out <- iconv(out, from = "", to = "UTF-8", sub = "")
      val <- out[grepl("^[0-9A-Fa-f]{64}$", trimws(out))]
      if (length(val)) trimws(val[1]) else NA_character_
    }
  } else {
    system2("sha256sum", path, stdout = TRUE)
  }
}
hashes <- data.frame(
  file = gsub("\\\\", "/", all_rel_files),
  size_bytes = file.info(all_files)$size,
  sha256 = vapply(all_files, hash_cmd, character(1)),
  stringsAsFactors = FALSE
)
safe_write_csv(hashes, "03_data/metadata/file_hashes.csv")

log_event("END 01_download_and_audit status=0")
