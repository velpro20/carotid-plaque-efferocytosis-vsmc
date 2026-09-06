# Reviewer-response sensitivity analysis

Run date: 2026-09-04T14:34:08+0800

Generated outputs:
- 05_results/tables/gene_set_category_audit.csv
- 05_results/tables/gene_set_overlap_jaccard.csv
- 05_results/tables/gene_set_platform_mapping_summary.csv
- 05_results/tables/main_correlation_leave_one_out.csv
- 05_results/tables/main_correlation_bootstrap_summary.csv
- 05_results/tables/main_correlation_exploratory_meta_summary.csv
- 05_results/tables/bulk_cell_composition_proxy_scores.csv
- 05_results/tables/main_correlation_partial_spearman_proxy_adjustment.csv
- 05_results/tables/GSE260657_donor_celltype_composition_group_summary.csv
- 05_results/tables/GSE260657_donor_celltype_composition_tests.csv

Interpretation boundaries:
- The main bulk correlation remains a tissue-level association in mixed plaque samples.
- Partial correlations use marker-score proxies rather than measured histology or deconvolution with validated reference profiles.
- Bootstrap and leave-one-out intervals quantify sensitivity but do not remove clinical heterogeneity or cell-composition confounding.
- scRNA donor composition tables are descriptive and donor-level; cells are not treated as independent patients.
