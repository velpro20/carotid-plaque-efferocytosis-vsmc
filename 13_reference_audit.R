# Purpose: retrieve and verify a focused bibliography for carotid plaque, efferocytosis,
#          VSMC state biology, single-cell transcriptomics, and analysis methods.
# Inputs: PubMed E-utilities via rentrez; curated accession PMIDs and topical searches.
# Outputs: 02_literature/reference_audit.csv and 06_manuscript/references.bib.
# Dependencies: base R; rentrez. Run after 00_preflight and before final manuscript QC.

set.seed(20260903)
source("04_scripts/_common.R")
ensure_project_dirs()
log_event("START 13_reference_audit")

if (!requireNamespace("rentrez", quietly = TRUE)) {
  record_error("13_reference_audit", "rentrez is not installed; bibliography audit blocked")
  stop("rentrez is required for structured PubMed verification")
}

Sys.setenv(ENTREZ_EMAIL = "codex@openai.com")

curated <- data.frame(
  pmid = c(
    "30335165", "41377472", "38639096", "40211055",
    "28137963", "32962412", "33630758", "27725526",
    "34029141", "32981416", "34617061", "34936041",
    "38389849", "38363908", "37469518", "35994249",
    "39552248", "41413386", "38362263", "39041203",
    "37471165", "40438929", "39613875",
    "25504845", "20810930", "22908242", "29939578",
    "24086464", "23662964"
  ),
  purpose = c(
    "discovery bulk dataset", "independent bulk validation dataset",
    "single-cell carotid plaque dataset", "related single-cell/source publication",
    "human atherosclerosis efferocytosis", "human atherosclerosis efferocytosis",
    "efferocytosis and plaque biology", "VSMC phenotypic modulation",
    "VSMC phenotypic modulation", "VSMC state biology",
    "carotid plaque/VSMC context", "VSMC state biology",
    "VSMC/atherosclerosis context", "VSMC/atherosclerosis context",
    "single-cell or immune plaque context", "single-cell or plaque context",
    "single-cell vascular cell state context", "single-cell vascular cell state context",
    "single-cell human atherosclerosis context", "human plaque single-cell context",
    "human plaque single-cell context", "human plaque single-cell context",
    "human carotid plaque context",
    "limma statistical method", "edgeR statistical method",
    "GSVA statistical method", "fgsea statistical method",
    "clusterProfiler enrichment method", "ReactomePA enrichment method"
  ),
  stringsAsFactors = FALSE
)

queries <- c(
  "carotid plaque symptomatic asymptomatic transcriptome",
  "atherosclerosis efferocytosis macrophage human plaque",
  "vascular smooth muscle cell phenotypic switching atherosclerosis",
  "single cell human carotid atherosclerotic plaque",
  "spatial transcriptomics atherosclerosis plaque human",
  "limma edgeR GSVA fgsea clusterProfiler ReactomePA"
)

search_ids <- unlist(lapply(queries, function(q) {
  out <- tryCatch(
    rentrez::entrez_search(db = "pubmed", term = q, retmax = 15),
    error = function(e) {
      record_error("13_reference_audit", paste("PubMed search failed:", q, e$message))
      NULL
    }
  )
  if (is.null(out)) character() else out$ids
}), use.names = FALSE)

candidate_ids <- unique(c(curated$pmid, search_ids))
fetch_one <- function(pmid) {
  tryCatch(
    rentrez::entrez_summary(db = "pubmed", id = pmid),
    error = function(e) {
      record_error("13_reference_audit", paste("PubMed summary failed:", pmid, e$message))
      NULL
    }
  )
}

summaries <- lapply(candidate_ids, fetch_one)
keep <- !vapply(summaries, is.null, logical(1))
summaries <- summaries[keep]
candidate_ids <- candidate_ids[keep]

extract_article_ids <- function(s) {
  ids <- s$articleids
  if (is.null(ids)) return(list())
  if (is.data.frame(ids)) {
    return(as.list(split(ids$value, ids$idtype)))
  }
  if (is.list(ids)) {
    return(ids)
  }
  list()
}

extract_authors <- function(s) {
  a <- s$authors
  if (is.null(a)) return(NA_character_)
  if (is.data.frame(a) && "name" %in% names(a)) return(paste(a$name, collapse = "; "))
  if (is.list(a)) {
    vals <- vapply(a, function(x) {
      if (is.list(x) && !is.null(x$name)) as.character(x$name) else as.character(x)
    }, character(1))
    return(paste(vals, collapse = "; "))
  }
  as.character(a)
}

extract_doi <- function(s) {
  ids <- extract_article_ids(s)
  if (length(ids)) {
    for (nm in names(ids)) {
      if (tolower(nm) == "doi") return(as.character(ids[[nm]][1]))
    }
  }
  NA_character_
}

extract_year <- function(s) {
  y <- s$pubdate %||% s$sortpubdate
  y <- as.character(y)[1]
  hit <- regmatches(y, regexpr("[0-9]{4}", y))
  ifelse(length(hit) && hit != "", hit, NA_character_)
}

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0L) y else x

rows <- lapply(seq_along(summaries), function(i) {
  s <- summaries[[i]]
  pmid <- as.character(candidate_ids[i])
  purpose <- curated$purpose[match(pmid, curated$pmid)]
  if (is.na(purpose)) purpose <- "topical PubMed candidate; relevance requires author review"
  data.frame(
    title = as.character(s$title %||% NA_character_),
    authors = extract_authors(s),
    journal = as.character(s$fulljournalname %||% s$source %||% NA_character_),
    year = extract_year(s),
    DOI = extract_doi(s),
    PMID = pmid,
    verified_url = paste0("https://pubmed.ncbi.nlm.nih.gov/", pmid, "/"),
    citation_purpose = purpose,
    verification_status = "PubMed metadata verified; abstract/source relevance requires final author review",
    stringsAsFactors = FALSE
  )
})

refs <- do.call(rbind, rows)
refs <- refs[!duplicated(refs$PMID), , drop = FALSE]

relevance_score <- function(title, purpose) {
  txt <- tolower(paste(title, purpose))
  score <- 0
  score <- score + 4 * grepl("carotid|atheroscl|plaque", txt)
  score <- score + 3 * grepl("efferocytosis|apoptotic|macrophage", txt)
  score <- score + 3 * grepl("smooth muscle|vsmc|phenotyp|vascular", txt)
  score <- score + 2 * grepl("single.?cell|transcriptom|spatial", txt)
  score <- score + 1 * grepl("limma|edger|gsva|fgsea|clusterprofiler|reactome", txt)
  score
}
refs$._score <- mapply(relevance_score, refs$title, refs$citation_purpose)

curated_first <- match(refs$PMID, curated$pmid)
refs$._curated <- !is.na(curated_first)
refs <- refs[order(!refs$._curated, -refs$._score, refs$year, refs$PMID), , drop = FALSE]
refs$._curated <- NULL
refs$._score <- NULL

if (nrow(refs) < 25L) {
  record_error("13_reference_audit",
               paste("Fewer than 25 PubMed records were retrievable:", nrow(refs)))
}

safe_write_csv(refs, "02_literature/reference_audit.csv")

escape_bib <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  gsub("[{}]", "", x)
}

make_key <- function(row, i) {
  first_author <- strsplit(row[["authors"]], ";", fixed = TRUE)[[1]][1]
  first_author <- gsub("[^A-Za-z0-9]", "", first_author)
  year <- ifelse(is.na(row[["year"]]) || row[["year"]] == "", "nd", row[["year"]])
  paste0(tolower(substr(first_author, 1, 12)), year, i)
}

bib_lines <- c(
  "% Generated by 04_scripts/13_reference_audit.R from PubMed metadata.",
  "% Reconcile numbered in-text citations with the final manuscript before submission.",
  ""
)
for (i in seq_len(nrow(refs))) {
  r <- refs[i, , drop = FALSE]
  key <- make_key(r, i)
  author <- gsub("; ", " and ", escape_bib(r$authors), fixed = TRUE)
  bib_lines <- c(
    bib_lines,
    paste0("@article{", key, ","),
    paste0("  author = {", author, "},"),
    paste0("  title = {", escape_bib(r$title), "},"),
    paste0("  journal = {", escape_bib(r$journal), "},"),
    paste0("  year = {", escape_bib(r$year), "},"),
    paste0("  pmid = {", escape_bib(r$PMID), "},"),
    paste0("  doi = {", escape_bib(r$DOI), "},"),
    paste0("  url = {", escape_bib(r$verified_url), "}"),
    "}",
    ""
  )
}
writeLines(bib_lines, "06_manuscript/references.bib", useBytes = TRUE)

writeLines(c(
  paste0("PubMed records written: ", nrow(refs)),
  paste0("Records with DOI metadata: ", sum(!is.na(refs$DOI) & refs$DOI != "")),
  "Metadata source: NCBI PubMed E-utilities via rentrez.",
  "Verification boundary: metadata existence is verified; relevance and exact use in manuscript require author review."
), "05_results/qc/reference_audit_summary.txt")

log_event(paste0("END 13_reference_audit status=0 records=", nrow(refs)))
