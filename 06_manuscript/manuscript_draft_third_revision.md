# Tissue-level covariation of efferocytosis-related and inflammatory VSMC transcriptional programs in clinically symptomatic versus asymptomatic human carotid plaques

Article type: Original Research

Running title: Efferocytosis-related and VSMC programs

Authors: [[AUTHOR NAME]]

Affiliations: [[AFFILIATION]]

Corresponding author: [[CORRESPONDING AUTHOR EMAIL]]

Manuscript status: third-round major-revision author-review draft. The text was revised with the Humanizer skill on 2026-09-04.

## Abstract

Background: Efferocytosis and vascular smooth muscle cell (VSMC) phenotypic modulation are relevant to atherosclerotic plaque biology. Their relationship in clinically symptomatic versus asymptomatic human carotid plaques remains uncertain. Methods: We reanalyzed public Gene Expression Omnibus datasets: GSE111782, an Affymetrix microarray discovery cohort with 9 symptomatic and 9 asymptomatic plaques; GSE311535, an independent diabetes-specific RNA-seq replication cohort with 6 symptomatic and 6 asymptomatic plaques; and GSE260657, a Smart-seq2 single-cell cohort with 8 symptomatic and 7 asymptomatic carotid plaque samples. Predefined efferocytosis-related and VSMC signatures were evaluated with assay-matched bulk models, ranked enrichment, sample-level scoring, Spearman correlation, and donor-level single-cell summaries. We added gene-set mapping, overlap, leave-one-out, bootstrap, and exploratory marker-proxy partial-correlation analyses. Results: The efferocytosis and inflammatory VSMC signatures had no direct gene overlap (Jaccard = 0). Mapping was high in both bulk cohorts: efferocytosis 29/30 and inflammatory VSMC 12/12 in GSE111782, and 30/30 and 12/12 in GSE311535. No individual gene reached FDR < 0.05 in either bulk cohort. No sample-level signature comparison between symptomatic and asymptomatic plaques reached FDR < 0.05. Efferocytosis-related scores correlated with inflammatory VSMC scores in GSE111782 (Spearman rho = 0.800, FDR = 0.0014; bootstrap 95% CI 0.484 to 0.933) and GSE311535 (rho = 0.881, FDR = 0.0015; bootstrap 95% CI 0.512 to 1.000). These correlations were observed in mixed plaque tissue and were not shown to represent macrophage-VSMC cell-cell coupling. In GSE260657, macrophage and VSMC compartments were localized, but donor-level program and cell-composition comparisons did not reach FDR < 0.05. Conclusion: The findings support a reproducible tissue-level association between efferocytosis-related and inflammatory VSMC expression scores across two heterogeneous bulk cohorts. They do not establish cell-specific coordination, mechanism, diagnostic utility, or pathology-defined plaque classification.

Keywords: carotid atherosclerosis; symptomatic plaque; asymptomatic plaque; efferocytosis; macrophage; vascular smooth muscle cell; transcriptomics

## Introduction

Human carotid atherosclerotic plaques are clinically important because symptomatic lesions are linked to cerebrovascular events. Symptom status is not the same as a pathology-defined plaque category. It can depend on thromboembolism, stenosis, vascular territory, collateral flow, prior events, and clinical ascertainment. For that reason, datasets labeled as symptomatic versus asymptomatic should retain those labels unless the source metadata provide a pathology grouping.

Macrophage clearance of apoptotic cells is one plausible process connecting inflammation resolution, necrotic-core biology, and advanced atherosclerosis. Efferocytosis involves recognition receptors, bridging molecules, engulfment machinery, lysosomal processing, and lipid-handling responses. Prior experimental and human studies have associated defective efferocytosis with plaque inflammation and necrosis [6-8].

VSMCs also change state in atherosclerotic plaques. They may lose contractile markers and acquire matrix-producing, inflammatory, osteogenic, or macrophage-like transcriptional features [9-13]. These shifts complicate bulk plaque transcriptomics because both cell abundance and cell state can change the measured signal.

Single-cell studies have shown substantial heterogeneity in human plaque tissue, including macrophage diversity and VSMC phenotypic modulation [12-20]. Less clear is whether a predefined efferocytosis-related transcriptional program covaries reproducibly with VSMC state programs in clinically symptomatic versus asymptomatic human carotid plaque cohorts.

We performed a secondary analysis of public human carotid plaque datasets under a deliberately bounded design. The study asked whether symptomatic plaques showed altered efferocytosis-related transcriptional features and whether those features were associated with non-contractile VSMC programs. We used one discovery bulk cohort, one independent heterogeneous bulk replication cohort, and one human carotid plaque single-cell cohort. The aim was to identify reproducible associations for follow-up, not to infer causality or relabel clinical groups as pathology-defined plaque types.

## Materials and Methods

### Data sources and cohort definitions

Public datasets were retained when metadata supported human carotid atherosclerotic plaque tissue and interpretable symptomatic versus asymptomatic grouping. GSE111782 served as the discovery bulk cohort. Its GEO record and linked publication describe post-bifurcation internal carotid atheroma samples with symptomatic and asymptomatic clinical labels [1,4,5]. The cohort included 18 samples, with 9 symptomatic and 9 asymptomatic plaques, profiled on the GPL571 Affymetrix Human Genome U133A 2.0 Array.

GSE311535 served as an independent heterogeneous bulk replication cohort. It contains human carotid plaque RNA-seq count data from patients with diabetes, including 6 symptomatic and 6 asymptomatic samples [2]. Because this cohort is diabetes-specific, it was not treated as a clinically identical validation cohort. GSE260657 was used for single-cell localization because the GEO record and linked publication describe Smart-seq2 data from 15 human carotid plaque samples, including 8 symptomatic and 7 asymptomatic samples [3]. Dataset provenance, URLs, limitations, and audit decisions are recorded in DATA_PROVENANCE.md and 03_data/metadata/dataset_audit.csv.

### Predefined gene sets and signature audit

The efferocytosis-related gene set was defined before inspecting project results. It contained 30 genes across recognition receptors, bridging molecules, integrin or scavenger uptake genes, inflammation-resolution or phosphatidylserine-binding genes, lipid-handling genes, and lysosomal-processing genes. The module counts were recognition_receptor: 3, bridging_molecule: 3, integrin_or_scavenger_uptake: 12, inflammation_resolution_or_ps_binding: 2, lipid_handling_resolution: 6, lysosomal_processing: 4. The full list is reported in 05_results/tables/gene_set_category_audit.csv. The genes were MERTK, AXL, TYRO3, GAS6, PROS1, MFGE8, ITGAV, ITGB3, ITGB5, CD36, STAB1, STAB2, LRP1, TIMD4, ANXA1, ANXA5, TREM2, APOE, ABCA1, ABCG1, NR1H3, PPARG, MARCO, MSR1, FCGR1A, FCGR3A, CTSD, CTSB, LAMP1, LAMP2.

VSMC signatures were predefined as separate contractile, synthetic, inflammatory, and ECM-remodeling/osteogenic programs. Each VSMC signature contained 12 genes. These signatures were treated as transcriptional programs, not definitive lineage-state labels. The complete gene lists, modules, and source bases are provided in 05_results/tables/gene_set_category_audit.csv.

Gene-set overlap was assessed before interpreting correlations. The efferocytosis-related and inflammatory VSMC signatures had 0 overlapping genes (Jaccard = 0). The only non-zero overlap among predefined VSMC signatures was between synthetic and ECM-remodeling/osteogenic VSMC sets, which shared COL1A1 and SPARC (Jaccard = 0.091). Platform mapping was also audited. GSE111782 mapped 29/30 efferocytosis-related genes, missing TIMD4, and 11/12 contractile VSMC genes, missing SYNPO2. All other predefined signatures mapped completely in GSE111782, and all listed signatures mapped completely in GSE311535.

### Bulk transcriptomic processing

GSE111782 was analyzed as an RMA-processed log2 microarray matrix. Probes without usable gene annotation were removed where possible. For duplicate gene mappings, the probe with the highest average expression was retained. The symptomatic-versus-asymptomatic contrast was fitted with limma empirical Bayes linear modeling [21]. The prespecified outlier rule flagged samples with missing fraction greater than 0.05 or median sample correlation below the cohort median minus 3 MAD. No sample was automatically removed by the script.

GSE311535 was analyzed as gene-level RNA-seq counts with edgeR quasi-likelihood negative-binomial models after low-expression filtering and library-size normalization [22]. TPM, FPKM, or log2 expression values were not used as raw counts. In both cohorts, positive log2 fold change denotes higher expression in symptomatic plaques relative to asymptomatic plaques.

### Signature, enrichment, and association analyses

Sample-level signature scores were calculated from the mapped genes available on each platform. Each score is the mean standardized expression of genes in that signature. Group comparisons used two-sided Wilcoxon rank-sum tests because the bulk cohorts were small and normality assumptions were not defensible. Median differences were summarized as symptomatic minus asymptomatic with bootstrap 95% intervals.

Ranked enrichment used preranked symptomatic-versus-asymptomatic statistics under the GSEA framework [24]. GO biological process, KEGG, and Reactome over-representation analyses were attempted using clusterProfiler and ReactomePA when gene mapping and package availability allowed [25-29]. Tissue-level associations between signatures were evaluated using Spearman correlations.

The Benjamini-Hochberg method controlled FDR within defined analysis families. These families were: genes within each differential-expression cohort; all predefined bulk signature group comparisons; all generated pairwise signature correlations; ranked predefined signatures within each cohort; GO, KEGG, and Reactome outputs within each cohort and database; single-cell donor-level program comparisons; and single-cell donor-level cell-composition comparisons. P values are two-sided where applicable, and FDR < 0.05 was the prespecified reporting threshold.

Correlation robustness was assessed with leave-one-out Spearman correlations and 5,000 bootstrap resamples. A fixed-effect Fisher z synthesis was calculated only as an exploratory descriptive summary. The cohorts were still reported separately because their clinical and technical differences are material.

To address cell-composition confounding in bulk data, exploratory rank-residual partial Spearman correlations adjusted the efferocytosis-inflammatory VSMC association for marker-score proxies. Three adjustment sets were used: macrophage plus VSMC marker scores; macrophage, VSMC, endothelial, and fibroblast marker scores; and a broad inflammation marker score. These are marker-score proxies, not measured histology or validated deconvolution estimates.

WGCNA was prespecified but not run. The discovery bulk sample size was 18, below the project threshold of at least 30 samples for stable network inference [30]. The optional machine-learning module was also skipped because the discovery and replication cohorts were small and did not yield an FDR-supported discovery marker set.

### Single-cell processing and annotation

GSE260657 raw Smart-seq2 text files were parsed without modifying the downloaded archive. The archived prespecified QC starting points were a minimum of 200 detected genes per cell, a maximum of 12,000 detected genes subject to platform review, a maximum mitochondrial fraction of 20%, and at least 50 cells per retained sample for descriptive outputs. The fallback parser reported detected genes, counts, mitochondrial fraction, donor metadata, marker scores, and cell type calls, but it did not implement complete doublet removal. High detected-gene cells therefore require author review before stronger inference.

Cell-level expression was log-normalized as log1p(counts per cell library size times 10,000). Feature selection used the top high-variance genes plus canonical markers, producing 1,228 features. PCA computed 20 components. K-means clustering used the first 10 PCs with k = 10, nstart = 25, and iter.max = 100. UMAP was skipped because the uwot package was not available in the locked environment.

Cell annotation used canonical marker-score winners, PCA/k-means support, and marker-candidate inspection. The main labels were macrophage, VSMC, endothelial cell, fibroblast, T/NK cell, B cell, mast cell, and unassigned. Calls with low or insufficiently separated marker scores were retained as unassigned. The S1-S3 macrophage and VSMC subcluster labels are descriptive labels from this analysis. They should not be read as validated biological subtypes.

Group comparisons used donor/sample-level summaries where possible. Individual cells were not treated as independent patients. Because donor identity was available through sample files, single-cell program and composition comparisons used donor-level Wilcoxon summaries. Cell-level plots were used for localization and descriptive variation.

### Reporting, software, and reproducibility

Analyses were performed in R 4.6.0 with limma 3.68.5, edgeR 4.10.4, GSVA 2.6.6, fgsea 1.38.0, clusterProfiler 4.20.0, ReactomePA, ggplot2 4.0.3, and related Bioconductor packages. Package versions are archived in 09_environment/package_versions.csv and 09_environment/session_info.txt. Scripts are stored in 04_scripts, logs in 08_logs, and generated tables and figures in 05_results. No sample was removed solely because it changed result direction or statistical significance.

## Results

### Cohort selection produced discovery, replication, and single-cell evidence layers

The dataset audit retained GSE111782 as the discovery bulk cohort, GSE311535 as an independent heterogeneous bulk replication cohort, and GSE260657 as the single-cell localization cohort (Figure 1). The two bulk cohorts were analyzed separately because they differed by platform, preprocessing, and clinical context. GSE311535 was diabetes-specific, which limits direct comparability with GSE111782. Optional spatial transcriptomics, cell-cell communication, WGCNA, and machine-learning modules were not used in the main conclusions because their prespecified gates were not met.

### Gene-set audit supported transparency and ruled out direct overlap for the main correlation

The efferocytosis-related signature contained 30 genes across six functional categories. VSMC programs were analyzed as four separate 12-gene signatures: contractile, synthetic, inflammatory, and ECM-remodeling/osteogenic. Platform mapping retained 29 of 30 efferocytosis-related genes in GSE111782 and all 30 in GSE311535. The inflammatory VSMC signature mapped completely in both cohorts. The efferocytosis-related and inflammatory VSMC signatures shared no genes, so the main correlation was not caused by direct gene overlap. The contribution audit showed that the aggregate efferocytosis score correlated most strongly with CTSB (rho = 0.947, FDR = 7.33e-08), NR1H3 (rho = 0.930, FDR = 3.44e-07), ABCA1 (rho = 0.856, FDR = 5.81e-05) in GSE111782 and ABCA1 (rho = 0.930, FDR = 3.51e-04), TREM2 (rho = 0.916, FDR = 4.18e-04), CTSB (rho = 0.909, FDR = 4.18e-04) in GSE311535. This audit indicates that lipid-handling and lysosomal components contribute substantially to the aggregate score.

### Bulk differential-expression analysis did not identify FDR-supported individual genes

In GSE111782, limma tested 14,289 genes and identified 0 genes at FDR < 0.05 (Figure 2). The smallest nominal P-value genes were SLC35F5 (log2FC = -2.068, P = 4.53e-04, FDR = 0.624), SOX5 (log2FC = -1.287, P = 0.0011, FDR = 0.624), ATP2B2 (log2FC = 1.444, P = 0.0022, FDR = 0.624). Their adjusted values were not below the prespecified threshold. In GSE311535, edgeR tested 21,925 genes and identified 0 genes at FDR < 0.05. The smallest nominal P-value genes were PI4KAP1 (log2FC = 1.308, P = 8.18e-05, FDR = 0.951), CTC-462L7.1 (log2FC = -0.480, P = 9.68e-04, FDR = 0.951), AC010886.2 (log2FC = -0.690, P = 0.0012, FDR = 0.951), again without FDR support. Across 10,864 genes available in both bulk cohorts, 6,609 (60.8%) had concordant symptomatic-versus-asymptomatic log2FC directions, but no gene reached FDR < 0.05 in both cohorts. The available data therefore do not support presenting individual genes as replicated markers.

### Discovery ranked enrichment was not reproduced in the replication cohort

Ranked enrichment of predefined signatures in GSE111782 identified FDR-supported negative enrichment for contractile_vsmc (NES = -1.987, FDR = 0.010); efferocytosis (NES = -1.601, FDR = 0.026); inflammatory_vsmc (NES = -1.809, FDR = 0.026); synthetic_vsmc (NES = -1.841, FDR = 0.026). Because positive log2FC denotes higher expression in symptomatic plaques, negative normalized enrichment scores mean that these genes tended to rank lower in symptomatic versus asymptomatic plaques. GO biological process over-representation in GSE111782 returned three FDR-supported terms related to cartilage or chondrocyte differentiation: regulation of chondrocyte differentiation (FDR = 0.035; genes: NR5A2, SOX5, BMPR1B, ZBTB16); positive regulation of chondrocyte differentiation (FDR = 0.035; genes: SOX5, BMPR1B, ZBTB16); regulation of cartilage development (FDR = 0.035; genes: NR5A2, SOX5, BMPR1B, ZBTB16). Reactome over-representation did not yield FDR-supported terms in the discovery output.

In GSE311535, none of the ranked predefined signatures reached FDR < 0.05. The lowest adjusted value was observed for efferocytosis (NES = 1.254, FDR = 0.170). The discovery enrichment pattern is therefore best treated as cohort-specific, not as a replicated symptomatic-versus-asymptomatic signature.

### Sample-level signature group differences did not survive FDR correction

No predefined efferocytosis or VSMC signature differed between symptomatic and asymptomatic plaques at FDR < 0.05 in either bulk cohort (Figure 3). In GSE111782, the efferocytosis median score was 0.374 in asymptomatic plaques and -0.021 in symptomatic plaques (median difference = -0.395, bootstrap 95% CI -0.985 to 0.632, P = 0.331, FDR = 0.757). The contractile VSMC score showed a nominal difference in GSE111782 (median difference = -0.418, bootstrap 95% CI -1.018 to -0.069, P = 0.034, FDR = 0.341), but it did not survive FDR correction. In GSE311535, the efferocytosis median score was -0.142 in asymptomatic plaques and 0.224 in symptomatic plaques (median difference = 0.366, bootstrap 95% CI -0.474 to 0.903, P = 0.575, FDR = 0.822). These results should be read as not detecting FDR-supported group differences at the current sample size and data quality.

### Efferocytosis-related scores covaried with inflammatory VSMC scores at tissue level

The most reproducible bulk observation was a positive tissue-level association between efferocytosis-related and inflammatory VSMC signatures. In GSE111782, the efferocytosis-related score correlated with the inflammatory VSMC score (Spearman rho = 0.800, P = 6.78e-05, FDR = 0.0014). Leave-one-out correlations ranged from 0.767 to 0.853. The bootstrap median rho was 0.798, with a 95% interval from 0.484 to 0.933. The efferocytosis-related score also correlated with the synthetic VSMC score in GSE111782 (rho = 0.593, P = 0.0094, FDR = 0.047), which was treated as supportive and exploratory.

In GSE311535, the efferocytosis-related score again correlated with the inflammatory VSMC score (rho = 0.881, P = 1.53e-04, FDR = 0.0015). Leave-one-out correlations ranged from 0.845 to 0.927. The bootstrap median rho was 0.891, with a 95% interval from 0.512 to 1.000. The association with ECM-remodeling VSMC was weaker and did not pass FDR correction (rho = 0.483, FDR = 0.204). An exploratory fixed-effect Fisher z summary gave a pooled rho of 0.835 with a 95% interval from 0.666 to 0.922, but cohort-specific results remain primary.

### Marker-proxy adjustment showed that the bulk correlation remains confounded

Exploratory partial Spearman analyses showed that the main correlation was sensitive to marker-proxy adjustment. In GSE111782, adjustment for macrophage plus VSMC marker scores attenuated the association (rho = 0.0093, P = 0.971, FDR = 0.971). Adjustment for four cell-type marker proxies also attenuated it (rho = -0.170, P = 0.499, FDR = 0.599), as did adjustment for a broad inflammation proxy (rho = -0.329, P = 0.182, FDR = 0.364). In GSE311535, the association persisted after adjustment for macrophage plus VSMC marker scores (rho = 0.755, P = 0.0045, FDR = 0.017) and after four cell-type marker proxies (rho = 0.741, P = 0.0058, FDR = 0.017). It was attenuated after broad inflammation-proxy adjustment (rho = 0.280, P = 0.379, FDR = 0.568). These analyses use expression proxies in very small cohorts. They support a cautious interpretation in which cell composition and shared inflammatory burden remain plausible explanations.

### Single-cell analysis localized macrophage and VSMC compartments without donor-level FDR-supported group differences

GSE260657 yielded 7,690 parsed cells across 15 donor/sample files. Detected genes ranged from 1499 to 15542, total counts from 49886 to 749583, and mitochondrial fraction from 4.14e-04 to 0.100. Marker-score annotation assigned the main cell classes as macrophage: 2271, fibroblast: 1645, vsmc: 1511, endothelial: 756, unassigned: 752, t_nk: 332, mast: 216, b_cell: 207 (Figure 4). Macrophages represented the largest annotated compartment (n = 2,271), and VSMCs were also represented (n = 1,511).

Secondary macrophage analysis produced three descriptive subclusters: macrophage_S1 n = 331, efferocytosis score = 0.730; macrophage_S2 n = 1184, efferocytosis score = 0.135; macrophage_S3 n = 756, efferocytosis score = 0.174 (Figure 5). Secondary VSMC analysis also produced three descriptive subclusters: vsmc_S1 n = 695, contractile score = 0.800, non-contractile score = -0.115; vsmc_S2 n = 519, contractile score = 1.064, non-contractile score = 0.223; vsmc_S3 n = 297, contractile score = 1.879, non-contractile score = 0.040 (Figure 6). Donor-level program comparisons across macrophage and VSMC compartments did not identify FDR-supported symptomatic-versus-asymptomatic differences (FDR < 0.05 comparisons: 0). Donor-level cell-composition tests also did not reach FDR < 0.05 (FDR < 0.05 comparisons: 0); the lowest adjusted values were endothelial n_cells (P = 0.013, FDR = 0.141); mast fraction_of_cells (P = 0.018, FDR = 0.141). These single-cell data support cellular localization of the predefined programs, but they do not establish group-level program differences or cell-specific coupling.

### Replication supported the tissue-level correlation but not a classifier or marker set

The independent heterogeneous replication cohort reproduced the positive tissue-level association between efferocytosis-related and inflammatory VSMC scores. It did not support individual DEGs, sample-level signature group shifts, or discovery ranked enrichment at FDR < 0.05 (Figure 7). The optional machine-learning module was skipped because both bulk cohorts were small and heterogeneous. It was also skipped because discovery plus replication did not establish an FDR-supported gene-level marker set. The results are therefore reported as transcriptional associations rather than a classification model.

## Discussion

This secondary analysis found limited evidence for symptomatic-versus-asymptomatic differential expression at the individual gene or sample-level signature level. Neither bulk cohort produced FDR-supported individual genes. No predefined efferocytosis-related or VSMC sample-level signature comparison reached FDR < 0.05. These findings reduce support for a simple group-discriminating transcriptomic signature in the available public cohorts. They should not be read as proof that no biological differences exist.

The most consistent result was a tissue-level association between efferocytosis-related scores and inflammatory VSMC scores across two bulk cohorts. The association was observed in the discovery microarray cohort and in the independent diabetes-specific RNA-seq cohort. Gene-set overlap did not explain the main association because the efferocytosis-related and inflammatory VSMC signatures shared no genes. The association is biologically plausible in light of work on efferocytosis, inflammatory plaque states, and VSMC phenotypic modulation [6-14]. Still, it remains an association in mixed tissue.

The new sensitivity analyses narrow the interpretation. Leave-one-out and bootstrap analyses showed that the rank correlation was not driven by removal of a single sample in either cohort. Marker-proxy adjustment gave a more cautious message. The association was strongly attenuated in GSE111782 after adjustment for macrophage and VSMC proxies, four cell-type proxies, or broad inflammation. In GSE311535, it persisted after cell-type proxy adjustment but weakened after broad inflammation adjustment. These results are compatible with a tissue-level relationship, but they do not separate cellular composition, shared inflammation, lesion stage, and true cell-state coordination.

The replication cohort strengthens the observation because it was independent and used a different assay type. Its diabetes-specific context also limits generalization. Diabetes status, medication use, tissue handling, symptom definitions, surgery timing, and plaque sampling site may differ between cohorts. GSE311535 should therefore be understood as an independent heterogeneous replication cohort, not as a fully matched validation set.

The single-cell cohort helped localize the relevant compartments. Macrophages and VSMCs were both represented in human carotid plaque data, and efferocytosis-related and VSMC-state programs could be scored. Donor-level program and cell-composition comparisons did not reach FDR < 0.05. The S1-S3 subclusters are descriptive, and the fallback workflow lacked complete doublet removal, UMAP visualization, reference mapping, and full integration. These constraints prevent a stronger claim that symptomatic plaques consistently contain an efferocytosis-high macrophage state or a non-contractile VSMC state.

The discovery enrichment results should also be read cautiously. In GSE111782, several predefined signatures were negatively enriched along the symptomatic-versus-asymptomatic ranked list. These enrichment signals were not reproduced in GSE311535. Platform mapping was high, but microarray probe selection, RNA-seq filtering, background gene definitions, diabetes status, sample size, and unmeasured tissue composition could all contribute to this non-replication. The cartilage and chondrocyte GO results were based on small leading gene sets and should be interpreted as exploratory.

Several limitations remain before submission. All analyses used retrospective public datasets, and harmonized patient-level covariates were limited. Symptom status was used exactly as reported and was not treated as pathology-defined plaque status. Bulk plaque tissue mixes immune, stromal, endothelial, smooth muscle, and other cell populations, so tissue-level signature associations may be composition-driven. Marker-proxy adjustment cannot replace histology or validated deconvolution. The single-cell workflow was a reproducible fallback analysis rather than a full Seurat or Scanpy reanalysis of processed objects. No spatial carotid validation, lineage tracing, perturbation experiment, or wet-lab validation was performed. The study was not powered prospectively; bootstrap intervals summarize precision but do not solve small-sample limitations.

In summary, public human carotid plaque transcriptomes support a reproducible association between tissue-level efferocytosis-related and inflammatory VSMC expression scores across two heterogeneous bulk cohorts. They do not establish cell-specific coordination, mechanism, robust symptomatic-versus-asymptomatic DEGs, or validated group-discriminating signatures. Future studies should test these candidate associations in prospectively phenotyped carotid plaque cohorts with harmonized clinical definitions, histology, spatial validation, and experimental models that can separate cell-state changes from cell-composition effects.

## Data Availability Statement

Public datasets were analyzed in this study. They are available through the Gene Expression Omnibus under GSE111782, GSE311535, and GSE260657. Accession-level URLs, download dates, file names, processing scripts, generated outputs, uses, and limitations are recorded in DATA_PROVENANCE.md and 03_data/metadata/dataset_audit.csv.

## Code Availability Statement

Analysis scripts, parameters, logs, intermediate tables, figures, and manuscript-generation scripts are included in this project directory. Before submission, the authors should archive the code in a persistent public repository and replace this placeholder with the repository URL: [[CODE REPOSITORY URL]].

## Ethics Statement

This manuscript reports a secondary analysis of public, de-identified human datasets. The original studies' ethics approval and consent statements must be verified from the corresponding source publications before submission: [[ETHICS STATEMENT TO BE VERIFIED]].

## Author Contributions

[[AUTHOR CONTRIBUTIONS TO BE COMPLETED BY REAL AUTHORS]]

## Funding

[[FUNDING INFORMATION]]

## Conflict of Interest

[[CONFLICT OF INTEREST DECLARATION]]

## Acknowledgments and AI Use Disclosure

Any generative AI assistance should be disclosed according to Frontiers policy. This project used AI assistance for code orchestration, manuscript organization, reviewer-response revision, and language editing. Quantitative analyses and figures were generated from public data using recorded scripts. The submitting authors must verify the final wording of this disclosure.

## Contribution to the Field

Human carotid plaque transcriptomic studies often compare symptomatic and asymptomatic plaques. These clinical labels can be confused with pathology-defined categories or with causal mechanisms. This study provides a reproducible public-data analysis of whether efferocytosis-related transcriptional features are associated with VSMC state programs in clinically defined human carotid plaques. The main reproducible signal is tissue-level covariation between efferocytosis-related and inflammatory VSMC scores in two independent bulk cohorts. The analysis also shows that individual DEGs and sample-level signature group differences are not FDR-supported in the available cohorts. The single-cell analysis localizes macrophage and VSMC compartments but does not treat cells as independent patients. The study therefore offers a transparent candidate association for future experimental and spatial validation, while avoiding causal, diagnostic, pathology-category, or treatment-actionability claims.

## References

1. Caparosa EM; Sedgewick AJ; Zenonos G; Zhao Y; Carlisle DL; Stefaneanu L; Jankowitz BT; Gardner P; Chang YF; Lariviere WR; LaFramboise WA; Benos PV; Friedlander RM. Regional Molecular Signature of the Symptomatic Atherosclerotic Carotid Plaque. Neurosurgery. 2019. doi: 10.1093/neuros/nyy470. PMID: 30335165.
2. Bradford A; Yoshida T; Sukhanov S; Woods FF; Delafontaine P; Bazan HA; Woods TC. Insulin use promotes pro-inflammatory changes in the transcriptome of atherosclerotic plaques in patients with diabetes mellitus. Journal of molecular and cellular cardiology plus. 2025. doi: 10.1016/j.jmccpl.2025.100829. PMID: 41377472.
3. Mocci G; Sukhavasi K; Örd T; Bankier S; Singha P; Arasu UT; Agbabiaje OO; Mäkinen P; Ma L; Hodonsky CJ; Aherrahrou R; Muhl L; Liu J; Gustafsson S; Byandelger B; Wang Y; Koplev S; Lendahl U; Owens GK; Leeper NJ; Pasterkamp G; Vanlandewijck M; Michoel T; Ruusalepp A; Hao K; Ylä-Herttuala S; Väli M; Järve H; Mokry M; Civelek M; Miller CJ; Kovacic JC; Kaikkonen MU; Betsholtz C; Björkegren JLM. Single-Cell Gene-Regulatory Networks of Advanced Symptomatic Atherosclerosis. Circulation research. 2024. doi: 10.1161/CIRCRESAHA.123.323184. PMID: 38639096.
4. Barrett T; Wilhite SE; Ledoux P; Evangelista C; Kim IF; Tomashevsky M; Marshall KA; Phillippy KH; Sherman PM; Holko M; Yefanov A; Lee H; Zhang N; Robertson CL; Serova N; Davis S; Soboleva A. NCBI GEO: archive for functional genomics data sets--update. Nucleic acids research. 2013. doi: 10.1093/nar/gks1193. PMID: 23193258.
5. Edgar R; Domrachev M; Lash AE. Gene Expression Omnibus: NCBI gene expression and hybridization array data repository. Nucleic acids research. 2002. doi: 10.1093/nar/30.1.207. PMID: 11752295.
6. Linton MF; Babaev VR; Huang J; Linton EF; Tao H; Yancey PG. Macrophage Apoptosis and Efferocytosis in the Pathogenesis of Atherosclerosis. Circulation journal : official journal of the Japanese Circulation Society. 2016. doi: 10.1253/circj.CJ-16-0924. PMID: 27725526.
7. Kojima Y; Weissman IL; Leeper NJ. The Role of Efferocytosis in Atherosclerosis. Circulation. 2017. doi: 10.1161/CIRCULATIONAHA.116.025684. PMID: 28137963.
8. Kasikara C; Schilperoort M; Gerlach B; Xue C; Wang X; Zheng Z; Kuriakose G; Dorweiler B; Zhang H; Fredman G; Saleheen D; Reilly MP; Tabas I. Deficiency of macrophage PHACTR1 impairs efferocytosis and promotes atherosclerotic plaque necrosis. The Journal of clinical investigation. 2021. doi: 10.1172/JCI145275. PMID: 33630758.
9. Miano JM; Fisher EA; Majesky MW. Fate and State of Vascular Smooth Muscle Cells in Atherosclerosis. Circulation. 2021. doi: 10.1161/CIRCULATIONAHA.120.049922. PMID: 34029141.
10. Chakraborty R; Chatterjee P; Dave JM; Ostriker AC; Greif DM; Rzucidlo EM; Martin KA. Targeting smooth muscle cell phenotypic switching in vascular disease. JVS-vascular science. 2021. doi: 10.1016/j.jvssci.2021.04.001. PMID: 34617061.
11. Zhang F; Guo X; Xia Y; Mao L. An update on the phenotypic switching of vascular smooth muscle cells in the pathogenesis of atherosclerosis. Cellular and molecular life sciences : CMLS. 2021. doi: 10.1007/s00018-021-04079-z. PMID: 34936041.
12. Depuydt MAC; Prange KHM; Slenders L; Örd T; Elbersen D; Boltjes A; de Jager SCA; Asselbergs FW; de Borst GJ; Aavik E; Lönnberg T; Lutgens E; Glass CK; den Ruijter HM; Kaikkonen MU; Bot I; Slütter B; van der Laan SW; Yla-Herttuala S; Mokry M; Kuiper J; de Winther MPJ; Pasterkamp G. Microanatomy of the Human Atherosclerotic Plaque by Single-Cell Transcriptomics. Circulation research. 2020. doi: 10.1161/CIRCRESAHA.120.316770. PMID: 32981416.
13. Pan H; Xue C; Auerbach BJ; Fan J; Bashore AC; Cui J; Yang DY; Trignano SB; Liu W; Shi J; Ihuegbu CO; Bush EC; Worley J; Vlahos L; Laise P; Solomon RA; Connolly ES; Califano A; Sims PA; Zhang H; Li M; Reilly MP. Single-Cell Genomics Reveals a Novel Cell State During Smooth Muscle Cell Phenotypic Switching and Potential Therapeutic Targets for Atherosclerosis in Mouse and Human. Circulation. 2020. doi: 10.1161/CIRCULATIONAHA.120.048378. PMID: 32962412.
14. Dib L; Koneva LA; Edsfeldt A; Zurke YX; Sun J; Nitulescu M; Attar M; Lutgens E; Schmidt S; Lindholm MW; Choudhury RP; Cassimjee I; Lee R; Handa A; Goncalves I; Sansom SN; Monaco C. Lipid-associated macrophages transition to an inflammatory state in human atherosclerosis increasing the risk of cerebrovascular complications. Nature cardiovascular research. 2023. doi: 10.1038/s44161-023-00295-x. PMID: 38362263.
15. Slysz J; Sinha A; DeBerge M; Singh S; Avgousti H; Lee I; Glinton K; Nagasaka R; Dalal P; Alexandria S; Wai CM; Tellez R; Vescovo M; Sunderraj A; Wang X; Schipma M; Sisk R; Gulati R; Vallejo J; Saigusa R; Lloyd-Jones DM; Lomasney J; Weinberg S; Ho K; Ley K; Giannarelli C; Thorp EB; Feinstein MJ. Single-cell profiling reveals inflammatory polarization of human carotid versus femoral plaque leukocytes. JCI insight. 2023. doi: 10.1172/jci.insight.171359. PMID: 37471165.
16. Horstmann H; Michel NA; Sheng X; Hansen S; Lindau A; Pfeil K; Fernández MC; Marchini T; Winkels H; Mitre LS; Abogunloko T; Li X; Mwinyella TB; Gissler MC; Bugger H; Heidt T; Buscher K; Hilgendorf I; Stachon P; Piepenburg S; Verheyen N; Rathner T; Gerhardt T; Siegel PM; Oswald WK; Cohnert T; Zernecke A; Madl J; Kohl P; Foks AC; von Zur Muehlen C; Westermann D; Zirlik A; Wolf D. Cross-species single-cell RNA sequencing reveals divergent phenotypes and activation states of adaptive immunity in human carotid and experimental murine atherosclerosis. Cardiovascular research. 2024. doi: 10.1093/cvr/cvae154. PMID: 39041203.
17. Barcia Durán JG; Das D; Gildea M; Amadori L; Gourvest M; Kaur R; Eberhardt N; Smyrnis P; Cilhoroz B; Sajja S; Rahman K; Fernandez DM; Faries P; Narula N; Vanguri R; Goldberg IJ; Fisher EA; Berger JS; Moore KJ; Giannarelli C. Immune checkpoint landscape of human atherosclerosis and influence of cardiometabolic factors. Nature cardiovascular research. 2024. doi: 10.1038/s44161-024-00563-4. PMID: 39613875.
18. Sukhavasi K; Mocci G; Ma L; Hodonsky CJ; Diez Benevante E; Muhl L; Liu J; Gustafsson S; Buyandelger B; Koplev S; Lendahl U; Vanlandewijck M; Singha P; Örd T; Beter M; Selvarajan I; Laakkonen JP; Väli M; den Ruijter HM; Civelek M; Hao K; Ruusalepp A; Betsholtz C; Järve H; Kovacic JC; Miller CL; Romanoski C; Kaikkonen MU; Björkegren JLM. Single-cell RNA sequencing reveals sex differences in the subcellular composition and associated gene-regulatory network activity of human carotid plaques. Nature cardiovascular research. 2025. doi: 10.1038/s44161-025-00628-y. PMID: 40211055.
19. Narayanan S; Vuckovic S; Bergman O; Wirka R; Verdezoto Mosquera J; Chen QS; Baldassarre D; Tremoli E; Veglia F; Lengquist M; Aherahrrou R; Razuvaev A; Gigante B; Björck HM; Miller CL; Quertermous T; Hedin U; Matic L. Atheroma transcriptomics identifies ARNTL as a smooth muscle cell regulator and with clinical and genetic data improves risk stratification. European heart journal. 2025. doi: 10.1093/eurheartj/ehae768. PMID: 39552248.
20. Raju S; Turner ME; Cao C; Abdul-Samad M; Punwasi N; Blaser MC; Cahalane RME; Botts SR; Prajapati K; Patel S; Wu R; Gustafson D; Galant NJ; Fiddes L; Chemaly M; Hedin U; Matic L; Seidman MA; Subasri V; Singh SA; Aikawa E; Fish JE; Howe KL. Multiomic Landscape of Extracellular Vesicles in Human Carotid Atherosclerotic Plaque Reveals Endothelial Communication Networks. Arteriosclerosis, thrombosis, and vascular biology. 2025. doi: 10.1161/ATVBAHA.124.322324. PMID: 40438929.
21. Ritchie ME; Phipson B; Wu D; Hu Y; Law CW; Shi W; Smyth GK. limma powers differential expression analyses for RNA-sequencing and microarray studies. Nucleic acids research. 2015. doi: 10.1093/nar/gkv007. PMID: 25605792.
22. Robinson MD; McCarthy DJ; Smyth GK. edgeR: a Bioconductor package for differential expression analysis of digital gene expression data. Bioinformatics (Oxford, England). 2010. doi: 10.1093/bioinformatics/btp616. PMID: 19910308.
23. Hänzelmann S; Castelo R; Guinney J. GSVA: gene set variation analysis for microarray and RNA-seq data. BMC bioinformatics. 2013. doi: 10.1186/1471-2105-14-7. PMID: 23323831.
24. Subramanian A; Tamayo P; Mootha VK; Mukherjee S; Ebert BL; Gillette MA; Paulovich A; Pomeroy SL; Golub TR; Lander ES; Mesirov JP. Gene set enrichment analysis: a knowledge-based approach for interpreting genome-wide expression profiles. Proceedings of the National Academy of Sciences of the United States of America. 2005. doi: 10.1073/pnas.0506580102. PMID: 16199517.
25. Yu G; Wang LG; Han Y; He QY. clusterProfiler: an R package for comparing biological themes among gene clusters. Omics : a journal of integrative biology. 2012. doi: 10.1089/omi.2011.0118. PMID: 22455463.
26. Yu G; He QY. ReactomePA: an R/Bioconductor package for reactome pathway analysis and visualization. Molecular bioSystems. 2016. doi: 10.1039/c5mb00663e. PMID: 26661513.
27. Gene Ontology Consortium. The Gene Ontology resource: enriching a GOld mine. Nucleic acids research. 2021. doi: 10.1093/nar/gkaa1113. PMID: 33290552.
28. Gillespie M; Jassal B; Stephan R; Milacic M; Rothfels K; Senff-Ribeiro A; Griss J; Sevilla C; Matthews L; Gong C; Deng C; Varusai T; Ragueneau E; Haider Y; May B; Shamovsky V; Weiser J; Brunson T; Sanati N; Beckman L; Shao X; Fabregat A; Sidiropoulos K; Murillo J; Viteri G; Cook J; Shorser S; Bader G; Demir E; Sander C; Haw R; Wu G; Stein L; Hermjakob H; D'Eustachio P. The reactome pathway knowledgebase 2022. Nucleic acids research. 2022. doi: 10.1093/nar/gkab1028. PMID: 34788843.
29. Kanehisa M; Furumichi M; Sato Y; Ishiguro-Watanabe M; Tanabe M. KEGG: integrating viruses and cellular organisms. Nucleic acids research. 2021. doi: 10.1093/nar/gkaa970. PMID: 33125081.
30. Langfelder P; Horvath S. WGCNA: an R package for weighted correlation network analysis. BMC bioinformatics. 2008. doi: 10.1186/1471-2105-9-559. PMID: 19114008.
