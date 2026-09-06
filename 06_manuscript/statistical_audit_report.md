# Statistical audit report

Scope: revised full manuscript draft, figure legends, and key result tables.

## Study design readout

- Discovery bulk cohort: GSE111782, n = 18 plaques, 9 symptomatic and 9 asymptomatic.
- Independent validation bulk cohort: GSE311535, n = 12 plaques, 6 symptomatic and 6 asymptomatic, diabetes-specific.
- Single-cell cohort: GSE260657, 15 donor/sample files, 8 symptomatic and 7 asymptomatic, 7,690 parsed cells.

## Independent unit and replication readout

- Bulk analyses use patient/plaque samples as the independent unit.
- Single-cell group comparisons use donor/sample summaries where possible.
- Cells are used for localization and descriptive subclustering, not as independent patient-level replicates.

## Major statistical issues found and fixed

- P1: The previous manuscript used scaffold wording such as "exact values are in tables" instead of reporting actual effect estimates and FDR values. Fixed by inserting traceable values from 05_results/tables.
- P1: Nominal findings could be overread. Fixed by explicitly stating that no individual DEG and no sample-level signature group comparison reached FDR < 0.05.
- P1: Correlations could be misread as mechanism. Fixed by labeling them as tissue-level associations and naming composition/stage confounding.
- P1: Single-cell pseudoreplication risk. Fixed by reporting donor-level tests and stating that cells were not treated as independent patients.
- P2: Optional modules were not clearly bounded. Fixed by stating that WGCNA, spatial validation, cell communication, and machine learning were skipped or excluded from main conclusions under prespecified gates.

## Remaining reviewer risks

- Small sample sizes limit power and precision.
- Validation cohort is diabetes-specific and not fully comparable with the discovery cohort.
- Full confidence in single-cell annotation would benefit from original processed objects or a full Seurat/Scanpy reanalysis.
- Exact ethics, funding, conflict-of-interest, author contribution, and code-repository details require real-author input.
