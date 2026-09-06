# Reproducibility notes

- Operating system: Windows PowerShell environment.
- Project execution date: 2026-09-03, Asia/Shanghai.
- Primary language: R 4.6.0.
- Random seed: 20260903 in every numbered R script.
- Source data: public GEO accessions; raw files kept unchanged.
- Discovery microarray: use limma after confirming RMA/log2 state and GPL571 annotation.
- Validation RNA-seq: use edgeR on gene-level counts after low-expression filtering.
- Signature scores: use GSVA/ssGSEA where available; fallback scores must be explicitly labeled.
- Multiple testing: Benjamini-Hochberg; primary threshold FDR < 0.05.
- Single-cell inference: donor/sample is the unit when available; cell counts are not treated as patient counts.
- Figure backend: R only. Export PDF, PNG, TIFF, and SVG when package support permits.
- Manuscript conversion: Word COM automation is attempted; failures are recorded.
- All commands, package versions, input files, and failures are logged.

