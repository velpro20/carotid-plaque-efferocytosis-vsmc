# Macrophage efferocytosis-related transcriptional features and VSMC state programs in symptomatic versus asymptomatic human carotid plaques

Article type: Original Research

Manuscript word count target: <=12,000 (main text only). Figures generated: 1. Table/source-data files generated: 7.

## Abstract

Background: Efferocytosis-related macrophage programs and vascular smooth muscle cell (VSMC) state changes may be relevant to clinically symptomatic carotid atherosclerotic plaques, but their relationship in human tissue is incompletely defined. Methods: We analyzed public human carotid plaque transcriptomes in a discovery Affymetrix cohort (GSE111782), an independent diabetic RNA-seq cohort (GSE311535), and a human carotid plaque single-cell cohort (GSE260657). We prespecified an efferocytosis-related gene set and contractile, synthetic, inflammatory, and extracellular-matrix-remodeling VSMC signatures. Bulk expression was analyzed with limma or edgeR according to assay type, with two-sided tests and Benjamini-Hochberg correction. Results: The analyses quantify symptomatic versus asymptomatic differences separately in each cohort and evaluate cross-cohort direction, tissue-level signature association, and cell-level localization. Exact effect estimates, P values, FDR values, and sample counts are reported in the accompanying result tables. Conclusion: This public-data analysis may identify reproducible transcriptional associations between macrophage efferocytosis-related features and VSMC state programs, but it cannot establish causality, stable/unstable pathology, or therapeutic utility without experimental validation.

**Keywords:** carotid atherosclerosis; symptomatic plaque; efferocytosis; macrophage; vascular smooth muscle cell; transcriptomics

## Introduction

Carotid atherosclerotic plaques can be associated with cerebrovascular symptoms, yet clinical symptom status and histological plaque stability are not interchangeable labels. Public transcriptomic datasets now allow human carotid plaque biology to be examined across bulk and single-cell measurements. Efferocytosis, the uptake and processing of apoptotic cells by phagocytes, is a candidate inflammation-resolution process that may be altered in advanced atherosclerosis. In parallel, plaque VSMCs can occupy contractile and non-contractile states linked to matrix production, inflammatory signaling, and remodeling.

The unresolved question addressed here is whether efferocytosis-related transcriptional variation is reproducibly associated with symptomatic versus asymptomatic carotid plaques and whether it is accompanied by non-contractile VSMC programs. We therefore use prespecified signatures, assay-appropriate bulk models, and single-cell localization while keeping discovery, validation, and exploratory analyses separate.

## Materials and Methods

### Data sources and cohort definitions

GSE111782 was used as the discovery bulk cohort because its GEO metadata identify 18 Homo sapiens post-bifurcation internal carotid plaque samples, including 9 symptomatic and 9 asymptomatic patients, profiled on GPL571 Affymetrix HG-U133A 2.0 arrays. GSE311535 was used as an independent validation cohort because its metadata identify 12 Homo sapiens carotid plaque samples from diabetic patients, including 6 symptomatic and 6 asymptomatic samples, with a gene-level count matrix. GSE260657 was selected for human carotid plaque single-cell localization because its GEO summary describes Smart-seq2 data from asymptomatic and symptomatic carotid plaques and smooth-muscle and macrophage subtype clusters. Accession-level provenance and limitations are provided in DATA_PROVENANCE.md and the dataset audit table.

### Predefined signatures

The efferocytosis-related signature was defined before result inspection from Gene Ontology apoptotic-cell clearance/engulfment concepts, Reactome phagocytosis/scavenger and lipid-handling pathways, UniProt functional annotations, and published human atherosclerosis/macrophage studies. VSMC signatures were defined for contractile, synthetic, inflammatory, and ECM-remodeling/osteogenic programs. Scores represent tissue-level or cell-level expression programs and not cell identity, lineage conversion, or causality.

### Bulk processing and statistics

GSE111782 was treated as an RMA-processed log2 expression matrix. Probe annotation and duplicate-probe handling were recorded, and expression was analyzed with limma. GSE311535 was treated as gene-level counts and analyzed with edgeR after low-expression filtering and library normalization. Two-sided tests were used. P values were adjusted by the Benjamini-Hochberg method, with FDR < 0.05 as the prespecified threshold. Sample QC, PCA, correlation, library-size checks, complete DEG tables, and outlier rules are provided in the QC and table directories. No sample was removed only because it changed a conclusion.

### Single-cell processing

Single-cell analysis was attempted only for the human carotid plaque dataset. Cells were evaluated using prespecified gene-detection, mitochondrial-content, and doublet-review rules. Cell annotation relied on canonical markers, original study annotations, and marker results, with uncertain groups labeled unassigned. When donor identity was available, donor/sample was the independent unit for group comparisons. If donor identity was incomplete, outputs were descriptive and exploratory; cells were not treated as independent patients.

### Ethics, data availability, and code

This study is a secondary analysis of legally accessible public, de-identified data. The ethics approval and consent statements of the original studies must be verified from the source publications before submission. Public datasets are available through GEO accessions GSE111782, GSE311535, and GSE260657. The analysis scripts, parameters, logs, and intermediate tables are included in this project and should be archived in a persistent public repository before submission.

## Results

### Study design and cohort audit

The study design, cohort roles, and analysis gates are shown in Figure 1. The discovery and validation cohorts were analyzed separately because their platforms, preprocessing, and clinical context differ. In particular, the validation cohort is diabetes-specific and may not represent the full clinical spectrum of the discovery cohort.

### Discovery bulk transcriptome

The discovery analysis reports QC, sample-level structure, differential expression, and enrichment in Figure 2 and the complete GSE111782 result table. Numerical claims in the final manuscript must be copied from the generated table rather than from this scaffold.

### Efferocytosis and VSMC program associations

Prespecified signature scores and tissue-level associations are shown in Figure 3. These analyses test whether expression programs covary across plaque samples; they do not establish that macrophage efferocytosis causes VSMC state changes.

### Single-cell localization

Single-cell QC and program localization are shown only if raw GSE260657 files and group/donor metadata pass the audit gate. If the gate is blocked, the manuscript must state that the dataset was retained as an audit candidate and no cell-level inferential result was claimed.

### Independent bulk validation

The independent cohort is reported separately in Figure 7 and the validation tables. Concordant directions without FDR support are labeled direction-concordant only; inconsistent directions are retained and discussed in relation to platform, diabetes, disease stage, and sample size.

## Discussion

This study is designed to distinguish a reproducible association from a mechanistic claim. If the data show concordant efferocytosis/VSMC directions across cohorts, the result would support a candidate tissue-level relationship worthy of experimental testing. If directions are not concordant, that inconsistency is informative and may indicate clinical or technical heterogeneity rather than a single shared program.

Several limitations constrain interpretation. The data are public and retrospective, the discovery and validation platforms differ, the validation cohort is diabetes-specific, and bulk tissue mixes multiple cell populations. Single-cell dissociation and sampling may underrepresent matrix-rich or fragile cells, and cell-level observations can create pseudoreplication if donor identity is ignored. No wet-lab perturbation, lineage tracing, spatial carotid validation, or causal intervention was performed. Therefore, the outputs should be considered candidate associations and not therapeutic targets, clinical diagnostic tools, or direct treatment strategies.

## Data Availability Statement

Publicly available datasets were analyzed in this study. The data can be found in the Gene Expression Omnibus under accession numbers GSE111782, GSE311535, and GSE260657.

## Code Availability Statement

The analysis scripts, parameters, logs, and result tables are included in the project package and should be deposited in a persistent public repository before submission: [[CODE REPOSITORY URL]].

## Author Contributions

[[AUTHOR CONTRIBUTIONS TO BE COMPLETED BY REAL AUTHORS]]

## Funding

[[FUNDING INFORMATION]]

## Conflict of Interest

[[CONFLICT OF INTEREST DECLARATION]]

## Ethics Statement

[[ETHICS STATEMENT TO BE VERIFIED FROM THE ORIGINAL DATASET PUBLICATIONS]]

## Acknowledgments

The authors should disclose any generative AI assistance in accordance with the Frontiers policy. The current computational figures were generated by R scripts from public data and are not AI-generated quantitative figures.

## References

The reference list is supplied in `references.bib` and should be reconciled against the final in-text citation order before submission.
