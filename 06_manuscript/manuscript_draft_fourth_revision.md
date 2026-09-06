# Tissue-level covariation of efferocytosis-related and VSMC-associated inflammatory transcriptional programs in clinically symptomatic versus asymptomatic human carotid plaques

Article type: Original Research

Running title: Efferocytosis-related plaque covariation

Author: Hong-Lin Guo

Affiliation: School of Pharmacy, Harbin University of Commerce, Harbin 150076, China

Corresponding author: Hong-Lin Guo, School of Pharmacy, Harbin University of Commerce, Harbin 150076, China. Email: [[CORRESPONDING AUTHOR EMAIL]]

## Abstract

Background: Efferocytosis-related transcription and vascular smooth muscle cell (VSMC) phenotypic modulation are both relevant to carotid atherosclerosis. Whether these programs covary in clinically symptomatic versus asymptomatic human carotid plaque transcriptomes remains uncertain.

Methods: We reanalyzed public Gene Expression Omnibus datasets. GSE111782 was used as a discovery bulk microarray cohort with 9 symptomatic and 9 asymptomatic plaques. GSE311535 was used as an independent heterogeneous RNA-seq replication cohort with 6 symptomatic and 6 asymptomatic plaques from patients with diabetes. GSE260657 was used for single-cell localization across 8 symptomatic and 7 asymptomatic carotid plaque sample files. Predefined efferocytosis-related and VSMC-state literature signatures were assessed using assay-matched bulk models, ranked enrichment, sample-level scores, Spearman correlations, bootstrap and leave-one-out analyses, marker-proxy partial correlations, and sample-file-level single-cell summaries.

Results: No individual gene reached FDR < 0.05 in either bulk cohort. No predefined sample-level signature comparison between symptomatic and asymptomatic plaques reached FDR < 0.05. The efferocytosis-related and inflammatory VSMC-associated signatures had no direct gene overlap (Jaccard = 0.000). Efferocytosis-related scores correlated with inflammatory VSMC-associated scores in GSE111782 (Spearman rho = 0.800, FDR = 0.001, bootstrap 95% CI 0.484 to 0.933) and GSE311535 (rho = 0.881, FDR = 0.002, bootstrap 95% CI 0.512 to 1.000). This reproducible signal was unadjusted and tissue-level. It was strongly attenuated in GSE111782 after marker-proxy adjustment and remained positive but imprecise in some GSE311535 proxy-adjusted analyses. A non-overlapping broad inflammation proxy attenuated the association in GSE111782 and reduced it below the FDR threshold in GSE311535. Single-cell analysis localized macrophage and VSMC compartments, but sample-file-level program and cell-composition comparisons did not reach FDR < 0.05. The 12-gene inflammatory VSMC-associated score was not VSMC-restricted in the single-cell data.

Conclusion: The findings support a reproducible unadjusted tissue-level correlation between efferocytosis-related and inflammatory VSMC-associated expression scores across two heterogeneous bulk cohorts. This association was variably attenuated by cell-type and broad inflammation marker proxies, while single-cell analyses did not establish VSMC specificity, cell-specific coordination, or group-level program differences. The findings should therefore be considered hypothesis-generating mixed-tissue covariation rather than evidence of a macrophage-VSMC mechanism, a pathology-defined plaque class, or a clinical-use marker.

Keywords: carotid atherosclerosis; symptomatic plaque; asymptomatic plaque; efferocytosis; macrophage; vascular smooth muscle cell; transcriptomics

## Introduction

Human carotid atherosclerotic plaques are often compared according to clinical symptom status because symptomatic lesions are associated with cerebrovascular events. Symptom status, however, is not a pathology-defined plaque class. It may reflect stenosis, thromboembolism, vascular territory, collateral flow, prior events, imaging criteria, and clinical selection. For this reason, this study retained the source labels symptomatic and asymptomatic and did not relabel them as pathology-defined plaque categories.

Macrophage clearance of apoptotic cells is one process that may connect inflammation resolution, necrotic-core biology, and advanced atherosclerosis. Efferocytosis involves recognition receptors, bridging molecules, engulfment machinery, lysosomal processing, and lipid-handling responses. Prior work has linked impaired efferocytosis to plaque inflammation and necrosis [6-8].

VSMCs also change phenotype in atherosclerotic tissue. They may lose contractile markers and acquire matrix-producing, osteogenic, inflammatory, or macrophage-like transcriptional features [9-13]. These transitions complicate bulk plaque transcriptomics because measured RNA can reflect both cell abundance and cell state.

Single-cell studies have described substantial heterogeneity in human plaque tissue, including macrophage diversity and VSMC phenotypic modulation [12-20]. Still, it remains unclear whether predefined efferocytosis-related transcription shows consistent unadjusted covariation with VSMC-state literature signatures in clinically symptomatic versus asymptomatic human carotid plaque cohorts.

We performed a bounded secondary analysis of public human carotid plaque datasets. The study asked whether symptomatic plaques showed consistent efferocytosis-related transcriptional changes and whether efferocytosis-related scores were associated with VSMC-state programs. One discovery bulk cohort, one independent heterogeneous bulk replication cohort, and one single-cell localization cohort were analyzed separately. The aim was to identify candidate mixed-tissue associations for follow-up, not to infer causality, build a diagnostic classifier, or redefine clinical plaque groups as pathology categories.

## Materials and Methods

### Data sources and cohort definitions

Public datasets were retained when the metadata supported human carotid atherosclerotic plaque tissue and interpretable symptomatic versus asymptomatic grouping. GSE111782 served as the discovery bulk cohort. Its GEO record and linked publication describe post-bifurcation internal carotid atheroma samples with symptomatic and asymptomatic clinical labels [1,4,5]. The cohort included 18 samples, with 9 symptomatic and 9 asymptomatic plaques, profiled on the GPL571 Affymetrix Human Genome U133A 2.0 Array.

GSE311535 served as an independent heterogeneous bulk replication cohort. It contains human carotid plaque RNA-seq count data from patients with diabetes, including 6 symptomatic and 6 asymptomatic samples [2]. Because this cohort is diabetes-specific, it was not treated as a clinically matched cohort. GSE260657 was used for single-cell localization because its GEO record and linked publication describe Smart-seq2 data from 15 human carotid plaque sample files, including 8 symptomatic and 7 asymptomatic sample files [3]. Dataset provenance, URLs, limitations, and audit decisions are recorded in the data provenance file and Supplementary Table 1.

### Predefined gene sets and proxy audit

The efferocytosis-related gene set contained 30 genes defined before inspecting project results. It included recognition receptors, bridging molecules, integrin or scavenger uptake genes, inflammation-resolution or phosphatidylserine-binding genes, lipid-handling genes, and lysosomal-processing genes. The genes were MERTK, AXL, TYRO3, GAS6, PROS1, MFGE8, ITGAV, ITGB3, ITGB5, CD36, STAB1, STAB2, LRP1, TIMD4, ANXA1, ANXA5, TREM2, APOE, ABCA1, ABCG1, NR1H3, PPARG, MARCO, MSR1, FCGR1A, FCGR3A, CTSD, CTSB, LAMP1, LAMP2.

VSMC programs were analyzed as separate contractile, synthetic, inflammatory VSMC-associated, and ECM-remodeling/osteogenic signatures. Each signature contained 12 genes. These were treated as literature-informed transcriptional programs, not definitive lineage-state measurements. The inflammatory VSMC-associated signature contained IL6, CCL2, CCL5, CXCL8, CXCL12, ICAM1, VCAM1, NFKB1, RELA, STAT3, TNF, and IL1B. Because several of these genes are not VSMC-restricted and may be expressed by immune, endothelial, or stromal cells, the bulk score was not interpreted as a VSMC-specific measurement.

Gene-set overlap was audited before interpreting correlations. The efferocytosis-related and inflammatory VSMC-associated signatures shared 0 genes (Jaccard = 0.000). Platform mapping retained 29/30 efferocytosis-related genes and 12/12 inflammatory VSMC-associated genes in GSE111782. It retained 30/30 and 12/12 genes, respectively, in GSE311535.

Marker-proxy adjustment used exploratory marker scores. Full proxy gene lists, overlap audits, proxy correlations, and collinearity summaries are provided in Supplementary Tables 2-4. The macrophage proxy overlapped with 4 efferocytosis-related genes (APOE;TREM2;MSR1;FCGR1A). The VSMC proxy overlapped with 9 contractile VSMC genes (ACTA2;TAGLN;MYH11;CNN1;CALD1;MYL9;TPM2;DES;MYLK). The non-overlapping broad inflammation proxy was introduced during revision as an exploratory sensitivity analysis to assess whether the main correlation was attributable to generalized inflammatory burden. It was defined to avoid direct overlap with the inflammatory VSMC-associated and efferocytosis-related signatures (overlap with inflammatory VSMC-associated signature = 0) and was not treated as a prespecified confirmatory covariate. These overlaps mean that proxy-adjusted analyses are sensitivity analyses, not evidence of independent causal effects.

### Bulk transcriptomic processing

GSE111782 was analyzed as an RMA-processed log2 microarray matrix. Probes without usable gene annotation were removed where possible. For duplicate gene mappings, the probe with the highest average expression was retained. The symptomatic-versus-asymptomatic contrast was fitted with limma empirical Bayes linear modeling [21]. The prespecified outlier rule flagged samples with missing fraction greater than 0.05 or median sample correlation below the cohort median minus 3 MAD. No sample was automatically removed by the script.

GSE311535 was analyzed as gene-level RNA-seq counts with edgeR quasi-likelihood negative-binomial models after low-expression filtering and library-size normalization [22]. TPM, FPKM, or log2 expression values were not used as raw counts. In both cohorts, positive log2 fold change denotes higher expression in symptomatic plaques relative to asymptomatic plaques.

### Signature, enrichment, and association analyses

Sample-level signature scores were calculated as the unweighted mean of mapped genes after z-score standardization within each cohort and platform. Missing or unmapped genes were omitted from the score for that dataset, and the number of mapped genes was recorded for each signature and cohort. Bulk and single-cell scores were computed separately, without cross-platform pooling. Group comparisons used two-sided Wilcoxon rank-sum tests because the bulk cohorts were small and normality assumptions were not defensible. Median differences were summarized as symptomatic minus asymptomatic with percentile bootstrap 95% intervals.

Ranked enrichment used preranked symptomatic-versus-asymptomatic statistics under the GSEA framework [24]. GO biological process, KEGG, and Reactome over-representation analyses were attempted when gene mapping and package availability allowed [25-29]. Tissue-level associations between signatures were evaluated using Spearman correlations.

Benjamini-Hochberg correction controlled FDR within defined analysis families. These families were genes within each differential-expression cohort; predefined bulk signature group comparisons across both bulk cohorts; all pairwise predefined signature correlations within each bulk cohort; ranked predefined signatures within each cohort; GO, KEGG, and Reactome outputs within each cohort and database; sample-file-level single-cell program comparisons; and sample-file-level single-cell cell-composition comparisons. Proxy-adjusted partial correlations formed a separate exploratory family across the two bulk cohorts and three adjustment models. The reduced four-gene score, leave-one-gene-out checks, and single-cell specificity summaries were revision-stage exploratory analyses and were not interpreted as prespecified confirmatory endpoints. P values are two-sided where applicable, and FDR < 0.05 was the prespecified reporting threshold for confirmatory reporting.

Correlation robustness was assessed with leave-one-out Spearman correlations and 5,000 bootstrap resamples at the sample level. Spearman P values were two-sided and used the asymptotic test where ties or sample size made exact calculation unsuitable. Exploratory rank-residual partial Spearman correlations first rank-transformed the two signature scores and covariate marker scores, then correlated residuals after linear adjustment for the selected marker proxies. Three adjustment sets were used: macrophage plus VSMC markers; macrophage, VSMC, endothelial, and fibroblast markers; and the revision-stage non-overlapping broad inflammation marker proxy. Bootstrap intervals for partial correlations refitted the residualization model within each resample. Because the cohorts were small, especially GSE311535 with 12 samples, adjusted estimates were interpreted as sensitivity analyses.

WGCNA was prespecified but not run because the discovery bulk sample size was 18, below the project threshold of at least 30 samples for stable network inference [30]. Machine-learning analysis was also skipped because the cohorts were small and did not yield an FDR-supported discovery marker set.

### Single-cell processing and annotation

GSE260657 raw Smart-seq2 text files were parsed without modifying the downloaded archive. The fallback parser reported detected genes, counts, mitochondrial fraction, marker scores, and cell type calls. It did not implement complete doublet removal. Cells with very high detected-gene counts therefore require author review before stronger inference.

Cell-level expression was log-normalized as log1p(counts per cell library size times 10,000). Feature selection used the top high-variance genes plus canonical markers, producing 1,228 features. PCA computed 20 components. K-means clustering used the first 10 PCs with k = 10, nstart = 25, and iter.max = 100. UMAP was skipped because the uwot package was not available in the locked environment.

Cell annotation used canonical marker-score winners, PCA/k-means support, and marker-candidate inspection. Main labels were macrophage, VSMC, endothelial cell, fibroblast, T/NK cell, B cell, mast cell, and unassigned. The S1-S3 macrophage and VSMC labels are descriptive program-score groups from this analysis. They should not be read as stable biological subtypes.

Group comparisons used sample-file-level summaries. Individual cells were not treated as independent patients. The available metadata identify GSM/sample files and symptom status, but the present analysis could not independently verify whether every sample file corresponds to a different patient. The conservative unit is therefore described as a sample file, and patient-level independence remains an author verification item.

### Reporting, software, and reproducibility

Analyses were performed in R 4.6.0 with limma 3.68.5, edgeR 4.10.4, GSVA 2.6.6, fgsea 1.38.0, clusterProfiler 4.20.0, ReactomePA, ggplot2 4.0.3, and related Bioconductor packages. Package versions, scripts, logs, generated tables, and generated figures are archived in the reproducibility package. No sample was removed solely because it changed result direction or statistical significance.

## Results

### Cohort selection produced independent evidence layers

The dataset audit retained GSE111782 as the discovery bulk cohort, GSE311535 as an independent heterogeneous bulk replication cohort, and GSE260657 as the single-cell localization cohort (Figure 1). The two bulk cohorts were analyzed separately because they differed by assay platform, preprocessing, and clinical context. GSE311535 was diabetes-specific, which limits direct comparability with GSE111782. Optional spatial transcriptomics, cell-cell communication, WGCNA, and machine-learning analyses were not used for the main conclusions because their prespecified gates were not met.

### Gene-set and proxy audits improved interpretability

The efferocytosis-related signature contained 30 genes across six functional categories. The inflammatory VSMC-associated signature mapped completely in both bulk cohorts and had no direct overlap with the efferocytosis-related signature. This ruled out direct reuse of identical genes as the explanation for the main unadjusted correlation.

The proxy audit also identified limits on adjusted analyses. The macrophage proxy shared APOE, TREM2, MSR1, and FCGR1A with the efferocytosis-related signature. The VSMC proxy shared 9 genes with the contractile VSMC signature. The non-overlapping broad inflammation proxy shared no genes with the efferocytosis-related or inflammatory VSMC-associated signatures. Proxy collinearity diagnostics were high in several models, including VIF-like values above 5 for some proxies. Adjusted analyses were therefore interpreted as exploratory checks for sensitivity to tissue composition and inflammatory burden.

### Bulk differential expression did not identify FDR-supported genes

In GSE111782, limma tested 14,289 genes and identified 0 genes at FDR < 0.05 (Figure 2). The smallest nominal P-value genes were SLC35F5 (log2FC -2.068, P = 4.53e-04, FDR = 0.624); SOX5 (log2FC -1.287, P = 0.001, FDR = 0.624); ATP2B2 (log2FC 1.444, P = 0.002, FDR = 0.624). Their adjusted values were not below the prespecified threshold. In GSE311535, edgeR tested 21,925 genes and identified 0 genes at FDR < 0.05. The smallest nominal P-value genes were PI4KAP1 (log2FC 1.308, P = 8.18e-05, FDR = 0.951); CTC-462L7.1 (log2FC -0.480, P = 9.68e-04, FDR = 0.951); AC010886.2 (log2FC -0.690, P = 0.001, FDR = 0.951), again without FDR support. The available data do not support presenting individual genes as replicated symptomatic-versus-asymptomatic markers.

### Discovery enrichment signals were not reproduced

Discovery-ranked enrichment suggested lower representation of several predefined programs in symptomatic plaques: contractile VSMC (NES -1.987, FDR = 0.010); efferocytosis-related (NES -1.601, FDR = 0.026); inflammatory VSMC-associated (NES -1.809, FDR = 0.026); synthetic VSMC (NES -1.841, FDR = 0.026). In GSE311535, none of the ranked predefined signatures reached FDR < 0.05. The lowest adjusted value was observed for efferocytosis-related (NES 1.254, FDR = 0.170). These enrichment results were therefore treated as cohort-specific exploratory observations.

### Sample-level signature group comparisons did not survive FDR correction

No predefined efferocytosis-related or VSMC program score differed between symptomatic and asymptomatic plaques at FDR < 0.05 in either bulk cohort. In GSE111782, the efferocytosis-related median score was 0.374 in asymptomatic plaques and -0.021 in symptomatic plaques (median difference -0.395, bootstrap 95% CI -0.985 to 0.632, P = 0.331, FDR = 0.757). The contractile VSMC score showed a nominal difference in GSE111782 (median difference -0.418, bootstrap 95% CI -1.018 to -0.069, P = 0.034, FDR = 0.341), but it did not survive FDR correction. In GSE311535, the efferocytosis-related median score was -0.142 in asymptomatic plaques and 0.224 in symptomatic plaques (median difference 0.366, bootstrap 95% CI -0.474 to 0.903, P = 0.575, FDR = 0.822). These results indicate that FDR-supported group differences were not detected at the current sample size and data quality.

### Efferocytosis-related and inflammatory VSMC-associated scores showed reproducible unadjusted tissue-level covariation

The main bulk observation, reproducible only in the unadjusted analysis, was a positive tissue-level correlation between efferocytosis-related and inflammatory VSMC-associated scores (Figure 3). In GSE111782, the correlation was rho = 0.800 (P = 6.78e-05, FDR = 0.001). Leave-one-out correlations ranged from 0.767 to 0.853, and the bootstrap 95% interval was 0.484 to 0.933. The efferocytosis-related score also correlated with the synthetic VSMC score in GSE111782 (rho = 0.593, FDR = 0.047), which was treated as supportive and exploratory.

In GSE311535, the efferocytosis-related score again correlated with the inflammatory VSMC-associated score (rho = 0.881, P = 1.53e-04, FDR = 0.002). Leave-one-out correlations ranged from 0.845 to 0.927, and the bootstrap 95% interval was 0.512 to 1.000. The association with ECM-remodeling/osteogenic VSMC score was weaker and did not pass FDR correction (rho = 0.483, FDR = 0.204).

### Marker-proxy adjustment weakened the claim of an independent association

Marker-proxy adjustment gave a more cautious interpretation. In GSE111782, the main association was nearly absent after adjustment for macrophage plus VSMC marker proxies (rho = 0.009, FDR = 0.971, bootstrap 95% CI -0.591 to 0.693), four cell-type proxies (rho = -0.170, FDR = 0.749, bootstrap 95% CI -0.789 to 0.651), or the non-overlapping broad inflammation proxy (rho = 0.086, FDR = 0.882, bootstrap 95% CI -0.466 to 0.645).

In GSE311535, the point estimate remained positive in the small exploratory analyses adjusted for macrophage plus VSMC marker proxies (rho = 0.755, FDR = 0.017, bootstrap 95% CI 0.011 to 1.000) and four cell-type proxies (rho = 0.741, FDR = 0.017, bootstrap 95% CI -0.725 to 1.000). The bootstrap intervals were wide, and the four-proxy model used only 12 samples with four covariates. After adjustment for the non-overlapping broad inflammation proxy, the association was lower and did not meet the FDR threshold (rho = 0.615, FDR = 0.066, bootstrap 95% CI -0.241 to 1.000). These results support a reproducible unadjusted mixed-tissue correlation, but not an independent macrophage-VSMC relationship after accounting for marker proxies.

### The inflammatory VSMC-associated signature was not VSMC-restricted in single-cell data

Single-cell expression analysis of the 12 inflammatory VSMC-associated genes showed broad expression across annotated compartments (Supplementary Figure 3). Dominant cell types by median mean expression were macrophage: 4; fibroblast: 3; t_nk: 2; endothelial: 1; mast: 1; vsmc: 1. At the sample-file level, the full inflammatory VSMC-associated score was not highest in VSMCs. The median sample-level score was 0.058 in T/NK cells, 0.006 in fibroblasts, and -0.132 in VSMCs. This supports the decision to avoid interpreting the bulk score as VSMC-specific.

A revision-stage data-driven sensitivity analysis retained four genes whose single-cell mean expression ranked within the top two cell types for VSMC: CXCL12, VCAM1, RELA, STAT3. The restricted score remained correlated with efferocytosis-related scores in both bulk cohorts (GSE111782: rho = 0.723, FDR = 0.001; GSE311535: rho = 0.727, FDR = 0.007). This analysis was generated after review of GSE260657 and was not a prespecified primary analysis or independent test. It indicates that the unadjusted association was not lost after one restricted-gene scoring rule, but it does not establish VSMC specificity or mechanism. Leave-one-gene-out analysis of the 12-gene score also retained positive correlations in both cohorts (GSE111782 rho range 0.777 to 0.822; GSE311535 rho range 0.748 to 0.881).

### Single-cell analysis localized major compartments without sample-file-level FDR-supported group differences

GSE260657 yielded 7,690 parsed cells across 15 sample files. Detected genes ranged from 1499 to 15542, total counts from 49886 to 749583, and mitochondrial fraction from 0.000 to 0.100. Marker-score annotation assigned the main cell classes as macrophage: 2,271; fibroblast: 1,645; vsmc: 1,511; endothelial: 756; unassigned: 752; t_nk: 332; mast: 216; b_cell: 207 (Figure 4). Supplementary marker dotplots supported the broad annotation pattern but did not replace full reference mapping.

Sample-file-level program comparisons across macrophage and VSMC compartments did not identify FDR-supported symptomatic-versus-asymptomatic differences (FDR < 0.05 comparisons: 0). Sample-file-level cell-composition tests also did not reach FDR < 0.05 (FDR < 0.05 comparisons: 0). Raw cell counts were treated as technical descriptors because capture efficiency, tissue dissociation, cell viability, sequencing depth, and filtering can affect them. Cell fractions were used descriptively and were not interpreted as definitive abundance changes.

The macrophage and VSMC S1-S3 outputs were retained as descriptive program-score groups (Figures 5 and 6). These labels do not establish stable biological subtypes, lineage transitions, or symptom-group-specific cell states. The single-cell layer therefore provided cellular localization and specificity assessment, but it did not validate the bulk correlation mechanistically.

### Replication did not support a classifier or marker set

The independent heterogeneous replication cohort showed the same unadjusted tissue-level efferocytosis-related and inflammatory VSMC-associated correlation, but it did not support individual DEGs, sample-level signature group shifts, or discovery-ranked enrichment at FDR < 0.05 (Figure 7). The machine-learning module was skipped because the cohorts were small and no FDR-supported gene-level marker set was established. The results are therefore reported as transcriptional associations rather than a classification model.

## Discussion

This secondary analysis found limited evidence for symptomatic-versus-asymptomatic differential expression at the individual gene or sample-level signature level. Neither bulk cohort produced FDR-supported individual genes, and no predefined sample-level signature comparison survived FDR correction. These results do not prove that biological differences are absent. They show that such differences were not detected with FDR support in the available public cohorts.

The most consistent observation was an unadjusted tissue-level correlation between efferocytosis-related and inflammatory VSMC-associated scores across two bulk cohorts. This association was observed in a microarray discovery cohort and an independent diabetes-specific RNA-seq replication cohort. Direct gene overlap did not explain the main correlation because the two primary signatures shared no genes.

The sensitivity analyses narrow the interpretation. Leave-one-out and bootstrap analyses showed that the unadjusted rank correlation was not driven by removing a single sample. In contrast, marker-proxy adjustment showed that the association was not consistently robust to tissue-composition and inflammation proxies. It was strongly attenuated in GSE111782 across all proxy models. In GSE311535, some cell-type proxy-adjusted point estimates remained positive, but they came from only 12 samples and had wide bootstrap intervals. The non-overlapping broad inflammation proxy also reduced the GSE311535 result below the FDR threshold. The main conclusion should therefore remain a reproducible unadjusted mixed-tissue covariation, not an independent cell-specific relationship.

The inflammatory VSMC-associated signature requires particular caution. Its 12 genes were selected from VSMC-state literature, but many are also expressed by immune, endothelial, or stromal cells. The single-cell analysis was consistent with this concern. The full score was not highest in VSMCs at the sample-file level, and several genes had dominant expression in macrophage, fibroblast, T/NK, endothelial, or mast compartments. A restricted four-gene sensitivity score remained correlated with efferocytosis-related scores in both bulk cohorts, but the subset was selected during revision and the genes are still not proof of VSMC-restricted biology. The safest interpretation is that efferocytosis-related transcription covaries with an inflammatory program that is VSMC-associated by literature selection but not VSMC-specific in mixed plaque tissue.

The replication cohort adds an independent dataset using a different assay type. Its diabetes-specific context also limits generalization. Diabetes status, medication use, tissue handling, symptom definitions, surgery timing, plaque sampling site, and RNA quality may differ between cohorts. GSE311535 should therefore be read as an independent heterogeneous replication cohort rather than a fully matched replication set.

The single-cell analysis helped localize relevant compartments, but it should not be overinterpreted. Macrophages and VSMCs were both represented, and candidate programs could be scored. Sample-file-level program and composition comparisons did not reach FDR < 0.05. The workflow used marker scores, PCA, and k-means as a scripted fallback. It did not include complete doublet removal, UMAP, reference mapping, or full integration. Sample files were used as the conservative unit because patient-level independence could not be independently verified from the current working metadata.

Discovery enrichment results were also limited. Several predefined signatures showed negative enrichment in GSE111782, but these signals were not reproduced in GSE311535. Platform mapping was high, yet microarray probe selection, RNA-seq filtering, background gene definitions, diabetes status, sample size, and unmeasured tissue composition could all contribute to non-replication. These enrichment outputs are best treated as exploratory and cohort-specific.

Several limitations remain before submission. The study used retrospective public datasets with limited harmonized patient-level covariates. Symptom status was retained exactly as reported and was not treated as pathology-defined plaque status. Bulk plaque tissue mixes immune, stromal, endothelial, smooth muscle, and other cell populations. Marker-proxy adjustment cannot replace histology, spatial transcriptomics, or formal deconvolution. The single-cell layer was a lightweight scripted analysis of public files rather than a full reanalysis from curated processed objects. No spatial transcriptomic support, lineage tracing, perturbation experiment, or wet-lab follow-up was performed. The study was not powered prospectively.

In summary, across two heterogeneous bulk cohorts, efferocytosis-related and inflammatory VSMC-associated scores showed reproducible unadjusted tissue-level covariation. However, the association was not consistently robust to marker-proxy adjustment, and the inflammatory VSMC-associated score was not VSMC-restricted in the single-cell analysis. The present data therefore support a candidate mixed-tissue transcriptional association, but do not establish cell-specific coordination, mechanism, or clinical utility.

## Data Availability Statement

Public datasets were analyzed in this study. They are available through the Gene Expression Omnibus under GSE111782, GSE311535, and GSE260657. Accession-level URLs, download dates, file names, processing scripts, generated outputs, uses, and limitations are recorded in the data provenance file and Supplementary Table 1.

## Code Availability Statement

Analysis scripts, parameters, logs, intermediate tables, figures, and manuscript-generation scripts are retained in the reproducibility package. Before submission, the author should archive the code in a persistent public repository and replace this placeholder with the repository URL: [[CODE REPOSITORY URL]].

## Ethics Statement

This manuscript reports a secondary analysis of public, de-identified human datasets. No new human participant recruitment, intervention, or specimen collection was performed for this analysis. The original studies' ethics approval and consent statements must be verified from the corresponding source publications before submission: [[SOURCE ETHICS AND CONSENT STATEMENTS TO BE VERIFIED]].

## Author Contributions

Hong-Lin Guo conceived the study, designed the analysis plan, curated the public datasets, performed the analyses, generated the figures and tables, drafted and revised the manuscript, and approved the author-review version.

## Funding

The author declares that no financial support was received for the research, authorship, and/or publication of this article.

## Conflict of Interest

The author declares that the research was conducted in the absence of any commercial or financial relationships that could be construed as a potential conflict of interest.

## Acknowledgments and AI Use Disclosure

The author thanks the investigators who generated and shared the public datasets analyzed here. AI-assisted tools were used for code orchestration, document organization, reviewer-comment integration, figure-format checking, and language editing. The author is responsible for reviewing the final manuscript, verifying all factual claims, and approving the submitted version.

## Contribution to the Field

Human carotid plaque transcriptomic studies often compare clinically symptomatic and asymptomatic plaques. These labels can be mistaken for pathology-defined categories or direct mechanism. This public-data reanalysis asks whether efferocytosis-related transcription covaries with VSMC-state literature programs in human carotid plaque datasets. The main reproducible unadjusted signal is a tissue-level correlation between efferocytosis-related and inflammatory VSMC-associated scores in two independent bulk cohorts. The analysis also shows that individual DEGs, sample-level group differences, and discovery-ranked enrichment were not reproduced with FDR support. Single-cell data localize relevant compartments and show that the inflammatory VSMC-associated signature is not VSMC-restricted. The study therefore provides a transparent candidate association for future spatial, histological, and experimental follow-up without making causal, diagnostic, treatment, or pathology-category claims.

## Figure Legends

Figure 1 | Study design, cohort roles, and analysis gates. Public human carotid plaque datasets were assigned to three independent evidence layers: discovery bulk analysis, heterogeneous bulk replication, and single-cell localization. The cohorts were analyzed separately and were not pooled. Symptomatic and asymptomatic labels are retained as reported in the source metadata.

Figure 2 | Discovery bulk sample structure and differential-expression results. GSE111782 was analyzed with limma using symptomatic versus asymptomatic plaques as the contrast. Panel a shows PCA-based sample structure. Panel b shows the volcano plot. Positive log2FC denotes higher expression in symptomatic plaques. No genes reached FDR < 0.05.

Figure 3 | Unadjusted tissue-level correlation and exploratory marker-proxy adjustment. Panels a and b show sample-level efferocytosis-related and inflammatory VSMC-associated scores in GSE111782 and GSE311535. Each point represents one bulk plaque sample, colored by clinical group. No fitted curve is used because of the small cohort sizes. Panel c shows Spearman rho with sample-level bootstrap 95% intervals. Panel d shows exploratory rank-residual partial Spearman analyses adjusted for marker-score proxies. These analyses do not establish cell-specific coupling or causality.

Figure 4 | Single-cell atlas and major-cell annotation for GSE260657. Smart-seq2 files were parsed from public raw data. Panel a shows PCA-based cellular localization. Panel b shows cell-type fractions by sample file. Major cell classes were assigned by marker-score and clustering support. Cells are shown for localization and are not independent patients.

Figure 5 | Descriptive macrophage program-score groups and efferocytosis-related scoring. Macrophage cells were analyzed descriptively to localize efferocytosis-related expression. Sample-file-level summaries, rather than cell counts, define the inferential unit for group comparisons. The S1-S3 labels are descriptive visualization groups and not established biological subtypes.

Figure 6 | Descriptive VSMC program-score groups and contractile/non-contractile scoring. VSMC cells were analyzed descriptively using predefined VSMC-state programs. These outputs indicate candidate localization and do not prove phenotypic conversion, lineage transition, or causality.

Figure 7 | Discovery and independent heterogeneous replication overview. Median symptomatic-minus-asymptomatic signature score directions are shown for both bulk cohorts. No sample-level signature group comparison reached FDR < 0.05. The reproducible finding is the unadjusted mixed-tissue efferocytosis-related and inflammatory VSMC-associated correlation.

Supplementary Figure 1 | Signature score group comparisons. Sample-level predefined signature scores are shown by cohort and clinical group. Wilcoxon group comparisons were adjusted using Benjamini-Hochberg correction.

Supplementary Figure 2 | Single-cell marker expression by annotated cell type. Dot size indicates the fraction of annotated cells within each cell type expressing each marker. Fill indicates median mean log1p CPM after summarizing expression by sample file and cell type.

Supplementary Figure 3 | Inflammatory VSMC-associated genes across single-cell compartments. The 12-gene inflammatory VSMC-associated signature is displayed across annotated cell types. Dot size indicates the fraction of annotated cells within each cell type expressing the gene, not the fraction of gene-expressing cells attributable to that cell type. Fill indicates median mean log1p CPM after summarizing expression by sample file and cell type. Expression outside VSMCs supports interpreting the bulk score as not VSMC-specific.

## References

1. Caparosa EM; Sedgewick AJ; Zenonos G; Zhao Y; Carlisle DL; Stefaneanu L; Jankowitz BT; Gardner P; Chang YF; Lariviere WR; LaFramboise WA; Benos PV; Friedlander RM. Regional Molecular Signature of the Symptomatic Atherosclerotic Carotid Plaque. Neurosurgery. 2019. doi: 10.1093/neuros/nyy470. PMID: 30335165.
2. Bradford A; Yoshida T; Sukhanov S; Woods FF; Delafontaine P; Bazan HA; Woods TC. Insulin use promotes pro-inflammatory changes in the transcriptome of atherosclerotic plaques in patients with diabetes mellitus. Journal of molecular and cellular cardiology plus. 2025. doi: 10.1016/j.jmccpl.2025.100829. PMID: 41377472.
3. Mocci G; Sukhavasi K; Örd T; Bankier S; Singha P; Arasu UT; Agbabiaje OO; Mäkinen P; Ma L; Hodonsky CJ; Aherrahrou R; Muhl L; Liu J; Gustafsson S; Byandelger B; Wang Y; Koplev S; Lendahl U; Owens GK; Leeper NJ; Pasterkamp G; Vanlandewijck M; Michoel T; Ruusalepp A; Hao K; Ylä-Herttuala S; Väli M; Järve H; Mokry M; Civelek M; Miller CJ; Kovacic JC; Kaikkonen MU; Betsholtz C; Björkegren JLM. Single-Cell Gene-Regulatory Networks of Advanced Symptomatic Atherosclerosis. Circulation research. 2024. doi: 10.1161/CIRCRESAHA.123.323184. PMID: 38639096.
4. Barrett T; Wilhite SE; Ledoux P; Evangelista C; Kim IF; Tomashevsky M; Marshall KA; Phillippy KH; Sherman PM; Holko M; Yefanov A; Lee H; Zhang N; Robertson CL; Serova N; Davis S; Soboleva A. NCBI GEO: archive for functional genomics data sets-update. Nucleic acids research. 2013. doi: 10.1093/nar/gks1193. PMID: 23193258.
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
