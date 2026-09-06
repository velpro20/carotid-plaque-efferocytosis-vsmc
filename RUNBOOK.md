# Runbook

All commands are recorded chronologically. Detailed stdout/stderr files are under `08_logs`.

| Start/end | Command or action | Status | Outputs | Error summary / action |
|---|---|---|---|---|
| 2026-09-03 | Created project directories | 0 | Required directory tree | None |
| 2026-09-03 | Retrieved official Frontiers pages with PowerShell `Invoke-WebRequest` | 0 | `03_data/raw/frontiers_*.html` | None |
| 2026-09-03 | Installed core R/Bioconductor packages | 0 | `09_environment/core_package_check.csv`, install log | None; versions recorded |
| 2026-09-03 | Downloaded GSE111782 matrix and raw CEL tar | 0 | `03_data/raw/GSE111782/*` | None |
| 2026-09-03 | First multi-file GEO download controller | timeout | Partial files retained | Large download exceeded 900 s; retried smaller files |
| 2026-09-03 | Downloaded GSE311535 matrix/counts and GSE260657 metadata/filelist | 0 | `03_data/raw/GSE311535/*`, `03_data/raw/GSE260657/*` | None |
| 2026-09-03 | Started GSE260657 raw archive retry using background curl | running/recheck | `03_data/raw/GSE260657/GSE260657_RAW.tar` | Recheck before scRNA execution |
| 2026-09-03 onward | Numbered reproducibility scripts | pending | `04_scripts/*` | Results and errors appended during execution |

| 2026-09-03T21:45:41 / 2026-09-03T21:45:51 | Rscript 04_scripts/00_preflight.R | 0 | See 08_logs/00_preflight.log | Automatically recorded |
| 2026-09-03T21:45:51 / 2026-09-03T21:45:51 | Rscript 04_scripts/01_download_and_audit.R | 1 | See 08_logs/01_download_and_audit.log | Automatically recorded |
| 2026-09-03T21:45:51 / 2026-09-03T21:46:07 | Rscript 04_scripts/02_bulk_qc_and_preprocess.R | 1 | See 08_logs/02_bulk_qc_and_preprocess.log | Automatically recorded |
| 2026-09-03T21:46:07 / 2026-09-03T21:46:08 | Rscript 04_scripts/03_bulk_differential_expression.R | 1 | See 08_logs/03_bulk_differential_expression.log | Automatically recorded |
| 2026-09-03T21:46:08 / 2026-09-03T21:48:27 | Rscript 04_scripts/04_signature_and_enrichment.R | 1 | See 08_logs/04_signature_and_enrichment.log | Automatically recorded |
| 2026-09-03T21:48:27 / 2026-09-03T21:48:27 | Rscript 04_scripts/05_network_analysis_optional.R | 0 | See 08_logs/05_network_analysis_optional.log | Automatically recorded |
| 2026-09-03T21:48:27 / 2026-09-03T21:48:27 | Rscript 04_scripts/06_scrna_qc_annotation.R | 0 | See 08_logs/06_scrna_qc_annotation.log | Automatically recorded |
| 2026-09-03T21:48:27 / 2026-09-03T21:48:27 | Rscript 04_scripts/07_scrna_macrophage_vsmc.R | 0 | See 08_logs/07_scrna_macrophage_vsmc.log | Automatically recorded |
| 2026-09-03T21:48:27 / 2026-09-03T21:48:27 | Rscript 04_scripts/08_cell_communication_optional.R | 0 | See 08_logs/08_cell_communication_optional.log | Automatically recorded |
| 2026-09-03T21:48:27 / 2026-09-03T21:48:28 | Rscript 04_scripts/09_spatial_validation_optional.R | 0 | See 08_logs/09_spatial_validation_optional.log | Automatically recorded |
| 2026-09-03T21:48:28 / 2026-09-03T21:48:28 | Rscript 04_scripts/10_external_validation.R | 1 | See 08_logs/10_external_validation.log | Automatically recorded |
| 2026-09-03T21:48:28 / 2026-09-03T21:48:28 | Rscript 04_scripts/11_figure_generation.R | 1 | See 08_logs/11_figure_generation.log | Automatically recorded |
| 2026-09-03T21:48:28 / 2026-09-03T21:48:52 | Rscript 04_scripts/12_manuscript_generation.R | 0 | See 08_logs/12_manuscript_generation.log | Automatically recorded |
| 2026-09-04T08:39:37 / 2026-09-04T08:39:37 | python 04_scripts/14_integrated_review_doc.py | 0 | 06_manuscript/integrated_review_document.docx; 08_logs/14_integrated_review_doc.log | Generated consolidated Word review document |
| 2026-09-04T09:17:12 / 2026-09-04T09:17:14 | python 04_scripts/15_skill_based_revision.py | 0 | 06_manuscript/manuscript_draft.md; 06_manuscript/manuscript_draft.docx; 06_manuscript/skill_based_review_report.md; 02_literature/reference_audit.csv | Skill-based manuscript audit, revision, and reference cleanup |
| 2026-09-04T09:18:46 / 2026-09-04T09:18:48 | python 04_scripts/15_skill_based_revision.py | 0 | 06_manuscript/manuscript_draft.md; 06_manuscript/manuscript_draft.docx; 06_manuscript/skill_based_review_report.md; 02_literature/reference_audit.csv | Skill-based manuscript audit, revision, and reference cleanup |
| 2026-09-04T09:19:11 / 2026-09-04T09:19:12 | python 04_scripts/14_integrated_review_doc.py | 0 | 06_manuscript/integrated_review_document.docx; 08_logs/14_integrated_review_doc.log | Generated consolidated Word review document |
| 2026-09-04T09:26:07 / 2026-09-04T09:26:07 | python 04_scripts/17_final_qc.py | 0 | 07_submission_package/FINAL_QC_REPORT.md; 07_submission_package/SUBMISSION_READINESS.md; 07_submission_package/DELIVERY_SUMMARY.md | Generated final QC and delivery reports |
| 2026-09-04T14:24:38 / 2026-09-04T14:34:08 | Rscript 04_scripts/18_review_response_sensitivity_analysis.R | 0 | 05_results\tables\gene_set_category_audit.csv; 05_results\tables\gene_set_overlap_jaccard.csv; 05_results\tables\gene_set_platform_mapping_summary.csv; 05_results\tables\main_correlation_bootstrap_summary.csv; 05_results\tables\main_correlation_partial_spearman_proxy_adjustment.csv; 05_results\tables\signature_group_effect_sizes_bootstrap.csv; 05_results\tables\GSE260657_donor_celltype_composition_tests.csv | Reviewer-response sensitivity analysis; initial script errors were fixed before final successful run |
| 2026-09-04T14:48:28 / 2026-09-04T14:48:28 | python 04_scripts/19_apply_major_review_revision.py | 0 | 修改内容\投稿正文_第三轮大修完善_Humanizer终版.docx; 修改内容\文章_第三轮大修完善_含图表整合版.docx; 修改内容\第三轮大修落实说明.docx; 修改内容\第三轮大修落实说明.md; 修改内容\第三轮处理日志.txt; 06_manuscript\manuscript_draft_third_revision.md | Applied major-review manuscript revision and Humanizer pass |
| 2026-09-04T15:57:03 / 2026-09-04T15:57:03 | Rscript 04_scripts/20_final_technical_revision_analysis_and_figures.R; python 04_scripts/21_apply_final_interpretive_revision.py | 0 | 修改内容\投稿正文_第四轮最终技术修订_Humanizer终版.docx; 修改内容\文章_第四轮最终技术修订_含图表整合版.docx | Fourth-round final technical revision, figures, SVG bundle, and Humanizer pass |
| 2026-09-04T15:58:54 / 2026-09-04T15:58:54 | Rscript 04_scripts/20_final_technical_revision_analysis_and_figures.R; python 04_scripts/21_apply_final_interpretive_revision.py | 0 | 修改内容\投稿正文_第四轮最终技术修订_Humanizer终版.docx; 修改内容\文章_第四轮最终技术修订_含图表整合版.docx | Fourth-round final technical revision, figures, SVG bundle, and Humanizer pass |
| 2026-09-04T16:10:58 / 2026-09-04T16:10:58 | Rscript 04_scripts/20_final_technical_revision_analysis_and_figures.R; python 04_scripts/21_apply_final_interpretive_revision.py | 0 | 修改内容\投稿正文_第四轮最终技术修订_Humanizer终版.docx; 修改内容\文章_第四轮最终技术修订_含图表整合版.docx | Fourth-round final technical revision, figures, SVG bundle, and Humanizer pass |
| 2026-09-04T16:15:35 / 2026-09-04T16:15:35 | Rscript 04_scripts/20_final_technical_revision_analysis_and_figures.R; python 04_scripts/21_apply_final_interpretive_revision.py | 0 | 修改内容\投稿正文_第四轮最终技术修订_Humanizer终版.docx; 修改内容\文章_第四轮最终技术修订_含图表整合版.docx | Fourth-round final technical revision, figures, SVG bundle, and Humanizer pass |
| 2026-09-04T16:37:21 / 2026-09-04T16:37:21 | Rscript 04_scripts/20_final_technical_revision_analysis_and_figures.R; python 04_scripts/21_apply_final_interpretive_revision.py | 0 | 修改内容\投稿正文_第四轮最终技术修订_Humanizer终版.docx; 修改内容\文章_第四轮最终技术修订_含图表整合版.docx | Fourth-round final technical revision, figures, SVG bundle, and Humanizer pass |
| 2026-09-04T16:39:23 / 2026-09-04T16:39:23 | Rscript 04_scripts/20_final_technical_revision_analysis_and_figures.R; python 04_scripts/21_apply_final_interpretive_revision.py | 0 | 修改内容\投稿正文_第四轮最终技术修订_Humanizer终版.docx; 修改内容\文章_第四轮最终技术修订_含图表整合版.docx | Fourth-round final technical revision, figures, SVG bundle, and Humanizer pass |
| 2026-09-04T16:41:40 / 2026-09-04T16:41:40 | Rscript 04_scripts/20_final_technical_revision_analysis_and_figures.R; python 04_scripts/21_apply_final_interpretive_revision.py | 0 | 修改内容\投稿正文_第四轮最终技术修订_Humanizer终版.docx; 修改内容\文章_第四轮最终技术修订_含图表整合版.docx | Fourth-round final technical revision, figures, SVG bundle, and Humanizer pass |
| 2026-09-04T16:43:06 / 2026-09-04T16:43:06 | Rscript 04_scripts/20_final_technical_revision_analysis_and_figures.R; python 04_scripts/21_apply_final_interpretive_revision.py | 0 | 修改内容\投稿正文_第四轮最终技术修订_Humanizer终版.docx; 修改内容\文章_第四轮最终技术修订_含图表整合版.docx | Fourth-round final technical revision, figures, SVG bundle, and Humanizer pass |
