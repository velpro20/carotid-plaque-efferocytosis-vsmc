# Carotid plaque efferocytosis and VSMC state project

## Question

This project tests whether macrophage efferocytosis-related transcriptional features differ between symptomatic and asymptomatic human carotid plaques and whether these tissue-level features are associated with contractile, synthetic, inflammatory, or ECM-remodeling VSMC programs.

## Data sources

Primary public sources are GEO accessions `GSE111782` (bulk microarray discovery), `GSE311535` (independent bulk RNA-seq validation), and `GSE260657` (human carotid plaque Smart-seq2 single-cell localization). All source files are kept unchanged in `03_data/raw`. Metadata and provenance are stored under `03_data/metadata`.

## Directory map

- `01_protocol`: protocol, journal compliance, QC parameters, and dataset rationale.
- `02_literature`: predefined gene sets and reference audit.
- `03_data/raw`: unchanged downloaded source files and official guideline snapshots.
- `03_data/metadata`: accession/sample metadata and audit CSV files.
- `03_data/processed`: parsed matrices and intermediate objects.
- `04_scripts`: numbered analysis scripts and `run_all.ps1`.
- `05_results`: tables, figures, and QC outputs.
- `06_manuscript`: Markdown, DOCX/PDF drafts, legends, tables, and supplementary material.
- `07_submission_package`: final QC, readiness, and delivery summary.
- `08_logs`: run logs, warnings, errors, and failure records.
- `09_environment`: session, package, and reproducibility information.

## Environment

R 4.6.0 is the primary analysis environment. Core packages include limma, edgeR, GEOquery, Biobase, GSVA when available, ggplot2, pheatmap, RColorBrewer, and jsonlite. Microsoft Word is used for DOCX/PDF conversion when available. No unrecorded interactive steps are required.

## Main command

From the project root:

```powershell
.\04_scripts\run_all.ps1
```

The total controller runs preflight, data audit/download checks, bulk preprocessing, differential expression, signatures/enrichment, scRNA audit/analysis when raw files are available, figure generation, manuscript generation, and final QC. Each step preserves intermediate outputs and appends to `RUNBOOK.md` and `08_logs`.

## Reproducibility

1. Run `00_preflight.R`.
2. Run `01_download_and_audit.R`.
3. Run `02_bulk_qc_and_preprocess.R`.
4. Run `03_bulk_differential_expression.R`.
5. Run `04_signature_and_enrichment.R`.
6. Run `06_scrna_qc_annotation.R` and `07_scrna_macrophage_vsmc.R`.
7. Run `11_figure_generation.R`.
8. Run `12_manuscript_generation.R`.
9. Run the final QC script through `run_all.ps1`.

The random seed, input paths, package versions, accession sources, parameters, and failure records are saved in `09_environment` and `08_logs`.

## Deliverables

The final package contains a data audit, reproducible scripts, QC and results tables, publication-style figures, an evidence-bounded manuscript draft, DOCX/PDF support files, supplementary materials, and a submission-readiness report. A completed manuscript must never be claimed if gates A, B, or C fail or if core results are not regenerated and traceable.

