# Project status

Last updated: 2026-09-04.

## Current stage

Manuscript revision and author-review packaging. The draft has been rewritten to remove scaffold wording, correct reference metadata, and align claims with the available evidence. A consolidated review Word file and skill-based audit reports are now generated.

## Completed

- Created required directory tree.
- Retrieved official Frontiers author, article-type, submission-checklist, publishing-fee, and publication-ethics pages.
- Identified GSE111782 as a symptomatic/asymptomatic bulk microarray discovery cohort.
- Identified GSE311535 as an independent symptomatic/asymptomatic bulk RNA-seq validation cohort.
- Identified GSE260657 as a human carotid plaque single-cell candidate with symptomatic/asymptomatic samples.
- Installed and recorded core R packages.
- Created protocol, compliance checklist, dataset rationale, and predefined gene-set files.
- Generated a consolidated Word review document at `06_manuscript/integrated_review_document.docx`, combining the revised manuscript text, key result summaries, skill-based review report, statistical audit report, reference-verification report, terminology ledger, main figures, figure legends, table inventory, supplementary-material inventory, dataset audit summary, source-file inventory, and expanded reference list.
- Rewrote `06_manuscript/manuscript_draft.md` and `06_manuscript/manuscript_draft.docx` to use only evidence-bounded language and real result values.
- Regenerated `02_literature/reference_audit.csv` and `06_manuscript/references.bib` with PubMed-verified metadata and corrected method/repository citations.

## Failed or incomplete

- The first multi-file download attempt timed out during a large single-cell archive download; partial files were preserved and the event was logged.
- Gate C is supported for review, but the single-cell annotation still uses a lightweight marker-score fallback rather than a full dedicated Seurat/Scanpy reanalysis.
- The manuscript remains an author-review draft, not a final submission package.

## Alternatives

- If the authors want a final submission package, the placeholders for author names, affiliations, funding, conflict, ethics, and code repository must be filled.
- If a stronger single-cell claim is needed, rerun the single-cell layer from processed objects or a full Seurat/Scanpy workflow.
- If journal formatting changes, regenerate the integrated Word document from the same script after updating the manuscript source.

## Author input needed

- Real author names, affiliations, corresponding author email, funding, conflict-of-interest, ethics/consent verification, acknowledgments, code repository URL, and invoice recipient.
- Confirmation of original-study ethics and consent statements.
- Final author review of any AI-use disclosure required by Frontiers.

## Final submission risks

- Public retrospective data and cross-cohort clinical heterogeneity.
- Discovery/validation platform difference and diabetes-specific validation cohort.
- Mixed tissue composition and possible cell-composition confounding.
- Small cohort sizes and limited clinical covariates.
- Potential single-cell pseudoreplication if donor identity is incomplete.
- No wet-lab validation or causal perturbation.

## 2026-09-04 Third-round major-review revision
- Completed: revised manuscript language and statistical reporting according to the major-review comments.
- Completed: integrated gene-set audit, overlap, mapping, bootstrap, leave-one-out, partial-correlation, and donor-level single-cell composition results.
- Completed: exported Times New Roman 12 pt, double-spaced Word files under 修改内容.
- Still author-dependent: author information, ethics/consent verification, funding, conflicts, repository URL, and final citation-to-claim audit.

## 2026-09-04 Fourth-round final technical revision
- Completed: author name, affiliation, author-contribution, no-funding, and no-conflict statements were inserted.
- Completed: main conclusion was weakened to unadjusted tissue-level covariation with proxy-adjustment limits.
- Completed: inflammatory VSMC program was renamed inflammatory VSMC-associated and audited in single-cell data.
- Completed: Figure 1 and Figure 3 were rebuilt, and supplementary single-cell dotplots were added.
- Completed: Times New Roman 12 pt, double-spaced Word files were exported under 修改内容.
- Still author-dependent: corresponding email, source-study ethics/consent verification, public code repository URL, and final citation audit.

## 2026-09-04 Fourth-round final technical revision
- Completed: author name, affiliation, author-contribution, no-funding, and no-conflict statements were inserted.
- Completed: main conclusion was weakened to unadjusted tissue-level covariation with proxy-adjustment limits.
- Completed: inflammatory VSMC program was renamed inflammatory VSMC-associated and audited in single-cell data.
- Completed: Figure 1 and Figure 3 were rebuilt, and supplementary single-cell dotplots were added.
- Completed: Times New Roman 12 pt, double-spaced Word files were exported under 修改内容.
- Still author-dependent: corresponding email, source-study ethics/consent verification, public code repository URL, and final citation audit.

## 2026-09-04 Fourth-round final technical revision
- Completed: author name, affiliation, author-contribution, no-funding, and no-conflict statements were inserted.
- Completed: main conclusion was weakened to unadjusted tissue-level covariation with proxy-adjustment limits.
- Completed: inflammatory VSMC program was renamed inflammatory VSMC-associated and audited in single-cell data.
- Completed: Figure 1 and Figure 3 were rebuilt, and supplementary single-cell dotplots were added.
- Completed: Times New Roman 12 pt, double-spaced Word files were exported under 修改内容.
- Still author-dependent: corresponding email, source-study ethics/consent verification, public code repository URL, and final citation audit.

## 2026-09-04 Fourth-round final technical revision
- Completed: author name, affiliation, author-contribution, no-funding, and no-conflict statements were inserted.
- Completed: main conclusion was weakened to unadjusted tissue-level covariation with proxy-adjustment limits.
- Completed: inflammatory VSMC program was renamed inflammatory VSMC-associated and audited in single-cell data.
- Completed: Figure 1 and Figure 3 were rebuilt, and supplementary single-cell dotplots were added.
- Completed: Times New Roman 12 pt, double-spaced Word files were exported under 修改内容.
- Still author-dependent: corresponding email, source-study ethics/consent verification, public code repository URL, and final citation audit.

## 2026-09-04 Fourth-round final technical revision
- Completed: author name, affiliation, author-contribution, no-funding, and no-conflict statements were inserted.
- Completed: main conclusion was weakened to unadjusted tissue-level covariation with proxy-adjustment limits.
- Completed: inflammatory VSMC program was renamed inflammatory VSMC-associated and audited in single-cell data.
- Completed: Figure 1 and Figure 3 were rebuilt, and supplementary single-cell dotplots were added.
- Completed: Times New Roman 12 pt, double-spaced Word files were exported under 修改内容.
- Still author-dependent: corresponding email, source-study ethics/consent verification, public code repository URL, and final citation audit.

## 2026-09-04 Fourth-round final technical revision
- Completed: author name, affiliation, author-contribution, no-funding, and no-conflict statements were inserted.
- Completed: main conclusion was weakened to unadjusted tissue-level covariation with proxy-adjustment limits.
- Completed: inflammatory VSMC program was renamed inflammatory VSMC-associated and audited in single-cell data.
- Completed: Figure 1 and Figure 3 were rebuilt, and supplementary single-cell dotplots were added.
- Completed: Times New Roman 12 pt, double-spaced Word files were exported under 修改内容.
- Still author-dependent: corresponding email, source-study ethics/consent verification, public code repository URL, and final citation audit.

## 2026-09-04 Fourth-round final technical revision
- Completed: author name, affiliation, author-contribution, no-funding, and no-conflict statements were inserted.
- Completed: main conclusion was weakened to unadjusted tissue-level covariation with proxy-adjustment limits.
- Completed: inflammatory VSMC program was renamed inflammatory VSMC-associated and audited in single-cell data.
- Completed: Figure 1 and Figure 3 were rebuilt, and supplementary single-cell dotplots were added.
- Completed: Times New Roman 12 pt, double-spaced Word files were exported under 修改内容.
- Still author-dependent: corresponding email, source-study ethics/consent verification, public code repository URL, and final citation audit.

## 2026-09-04 Fourth-round final technical revision
- Completed: author name, affiliation, author-contribution, no-funding, and no-conflict statements were inserted.
- Completed: main conclusion was weakened to unadjusted tissue-level covariation with proxy-adjustment limits.
- Completed: inflammatory VSMC program was renamed inflammatory VSMC-associated and audited in single-cell data.
- Completed: Figure 1 and Figure 3 were rebuilt, and supplementary single-cell dotplots were added.
- Completed: Times New Roman 12 pt, double-spaced Word files were exported under 修改内容.
- Still author-dependent: corresponding email, source-study ethics/consent verification, public code repository URL, and final citation audit.
