# GSE260657 single-cell gate

PASS: raw Smart-seq2 text files were parsed and donor-level symptom labels were verified from GEO metadata.
Cell-level QC, log-normalization, PCA, k-means clustering, marker-candidate tables, marker scoring, donor summaries, and PCA are available in the qc tables.
Cells are not treated as independent patients; downstream group summaries should use donor-level aggregation. 
