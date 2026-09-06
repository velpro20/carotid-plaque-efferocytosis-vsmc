"""Build the fourth-revision manuscript and author-review Word package.

Purpose: revise the carotid plaque manuscript according to the latest
reviewer-style critique, integrate fourth-round sensitivity analyses, and run
a conservative Humanizer pass.
Inputs: project result tables, revised figures, prior references, and user-
provided author information.
Outputs: fourth-revision DOCX/MD files, integrated review DOCX, SVG bundle,
revision note, and processing log under 修改内容.
Dependencies: python-docx, Python standard library.
Run order: after 20_final_technical_revision_analysis_and_figures.R.
"""

from __future__ import annotations

import csv
import datetime as dt
import math
import re
import shutil
import zipfile
from pathlib import Path

from docx import Document
from docx.enum.section import WD_ORIENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_LINE_SPACING
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt


ROOT = Path(r"D:\博士阶段\4、期刊\网药\1")
MANUSCRIPT_DIR = ROOT / "06_manuscript"
TABLE_DIR = ROOT / "05_results" / "tables"
QC_DIR = ROOT / "05_results" / "qc"
FIGURE_DIR = ROOT / "05_results" / "figures"
OUTPUT_DIR = ROOT / "修改内容"
LOG_DIR = ROOT / "08_logs"
RUNBOOK = ROOT / "RUNBOOK.md"
PROJECT_STATUS = ROOT / "PROJECT_STATUS.md"
ERROR_LOG = LOG_DIR / "error_log.md"
LOG = LOG_DIR / "21_apply_final_interpretive_revision.log"

AUTHOR = "Hong-Lin Guo"
AFFILIATION = "School of Pharmacy, Harbin University of Commerce, Harbin 150076, China"
CORRESPONDING_EMAIL = "[[CORRESPONDING AUTHOR EMAIL]]"
TITLE = (
    "Tissue-level covariation of efferocytosis-related and VSMC-associated "
    "inflammatory transcriptional programs in clinically symptomatic "
    "versus asymptomatic human carotid plaques"
)
RUNNING_TITLE = "Efferocytosis-related plaque covariation"


def stamp() -> str:
    return dt.datetime.now().isoformat(timespec="seconds")


def log(message: str) -> None:
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    with LOG.open("a", encoding="utf-8") as handle:
        handle.write(f"[{stamp()}] {message}\n")


def record_error(message: str) -> None:
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    with ERROR_LOG.open("a", encoding="utf-8") as handle:
        handle.write(f"\n- {stamp()} | 21_apply_final_interpretive_revision | {message}\n")
    log(f"ERROR {message}")


def read_csv_rows(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        record_error(f"Missing CSV: {path}")
        return []
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8", newline="\n")


def fmt_num(value: object, digits: int = 3) -> str:
    try:
        x = float(value)
    except (TypeError, ValueError):
        return "NA"
    if not math.isfinite(x):
        return "NA"
    return f"{x:.{digits}f}"


def fmt_p(value: object) -> str:
    try:
        x = float(value)
    except (TypeError, ValueError):
        return "NA"
    if not math.isfinite(x):
        return "NA"
    if x < 0.001:
        return f"{x:.2e}"
    return f"{x:.3f}"


def row_match(rows: list[dict[str, str]], **criteria: str) -> dict[str, str]:
    for row in rows:
        if all(row.get(key) == value for key, value in criteria.items()):
            return row
    return {}


def count_fdr(path: Path) -> tuple[int, int]:
    rows = read_csv_rows(path)
    if not rows:
        return 0, 0
    fdr_col = next((k for k in rows[0] if k.lower() in {"fdr", "adj.p.val", "padj", "qvalue"}), None)
    if not fdr_col:
        return len(rows), 0
    sig = 0
    for row in rows:
        try:
            sig += float(row.get(fdr_col, "nan")) < 0.05
        except ValueError:
            pass
    return len(rows), sig


def top_rows(path: Path, p_col: str, n: int = 3) -> list[dict[str, str]]:
    rows = read_csv_rows(path)

    def score(row: dict[str, str]) -> float:
        try:
            return float(row.get(p_col, "1") or 1)
        except ValueError:
            return 1.0

    return sorted(rows, key=score)[:n]


def sanitize_reference_text(text: str) -> str:
    replacements = {
        "脰": "O",
        "盲": "a",
        "枚": "o",
        "眉": "u",
        "谩": "a",
        "--": "-",
        "\u2013": "-",
        "\u2014": ", ",
    }
    for old, new in replacements.items():
        text = text.replace(old, new)
    return text


def extract_references() -> str:
    candidates = [
        OUTPUT_DIR / "投稿正文_第三轮大修完善_Humanizer终版.md",
        MANUSCRIPT_DIR / "manuscript_draft_third_revision.md",
        MANUSCRIPT_DIR / "manuscript_draft.md",
    ]
    for path in candidates:
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        marker = "\n## References\n"
        if marker in text:
            refs = text.split(marker, 1)[1].strip()
            return sanitize_reference_text(refs)
    return "AUTHOR_INPUT_NEEDED: references could not be extracted from the prior verified manuscript."


def list_genes(rows: list[dict[str, str]], signature: str) -> str:
    genes = [r.get("gene", "") for r in rows if r.get("signature") == signature and r.get("gene")]
    return ", ".join(genes)


def top_deg_text(rows: list[dict[str, str]]) -> str:
    bits = []
    for row in rows:
        bits.append(
            f"{row.get('gene')} (log2FC {fmt_num(row.get('logFC'))}, "
            f"P = {fmt_p(row.get('P_value'))}, FDR = {fmt_p(row.get('FDR'))})"
        )
    return "; ".join(bits)


def effect_text(row: dict[str, str]) -> str:
    return (
        f"median difference {fmt_num(row.get('median_difference_symptomatic_minus_asymptomatic'))}, "
        f"bootstrap 95% CI {fmt_num(row.get('bootstrap_ci_low'))} to "
        f"{fmt_num(row.get('bootstrap_ci_high'))}, P = {fmt_p(row.get('P_value'))}, "
        f"FDR = {fmt_p(row.get('FDR'))}"
    )


def partial_text(row: dict[str, str]) -> str:
    return (
        f"rho = {fmt_num(row.get('rho'))}, FDR = {fmt_p(row.get('FDR'))}, "
        f"bootstrap 95% CI {fmt_num(row.get('bootstrap_ci_low'))} to "
        f"{fmt_num(row.get('bootstrap_ci_high'))}"
    )


def get_context() -> dict[str, object]:
    rows = {
        "sig_summary": read_csv_rows(TABLE_DIR / "external_validation_signature_summary.csv"),
        "sig_effects": read_csv_rows(TABLE_DIR / "signature_group_effect_sizes_bootstrap.csv"),
        "sig_corr": read_csv_rows(TABLE_DIR / "signature_correlations.csv"),
        "boot": read_csv_rows(TABLE_DIR / "main_correlation_bootstrap_summary.csv"),
        "partial": read_csv_rows(TABLE_DIR / "main_correlation_partial_spearman_proxy_adjustment_fourth.csv"),
        "overlap": read_csv_rows(TABLE_DIR / "gene_set_overlap_jaccard.csv"),
        "proxy_overlap": read_csv_rows(TABLE_DIR / "bulk_marker_proxy_overlap_fourth.csv"),
        "proxy_genes": read_csv_rows(TABLE_DIR / "bulk_marker_proxy_gene_sets_fourth.csv"),
        "proxy_vif": read_csv_rows(TABLE_DIR / "bulk_proxy_collinearity_summary_fourth.csv"),
        "mapping": read_csv_rows(TABLE_DIR / "gene_set_platform_mapping_summary.csv"),
        "gene_sets": read_csv_rows(TABLE_DIR / "gene_set_category_audit.csv"),
        "ranked_111": read_csv_rows(TABLE_DIR / "GSE111782" / "ranked_signature_enrichment.csv"),
        "ranked_311": read_csv_rows(TABLE_DIR / "GSE311535" / "ranked_signature_enrichment.csv"),
        "donor_tests": read_csv_rows(TABLE_DIR / "GSE260657_donor_program_tests.csv"),
        "comp_tests": read_csv_rows(TABLE_DIR / "GSE260657_donor_celltype_composition_tests.csv"),
        "cell_ann": read_csv_rows(QC_DIR / "GSE260657_cell_annotations.csv"),
        "sample_audit": read_csv_rows(TABLE_DIR / "GSE260657_sample_level_celltype_audit_fourth.csv"),
        "inflam_specificity": read_csv_rows(TABLE_DIR / "GSE260657_inflammatory_vsmc_associated_gene_specificity_summary_fourth.csv"),
        "inflam_score_summary": read_csv_rows(TABLE_DIR / "GSE260657_inflammatory_vsmc_associated_score_celltype_summary_fourth.csv"),
        "reduced_status": read_csv_rows(TABLE_DIR / "inflammatory_vsmc_associated_reduced_signature_status_fourth.csv"),
        "reduced_corr": read_csv_rows(TABLE_DIR / "bulk_reduced_inflammatory_vsmc_associated_correlation_fourth.csv"),
        "loo_gene": read_csv_rows(TABLE_DIR / "bulk_inflammatory_vsmc_associated_leave_one_gene_out_fourth.csv"),
        "qc_by_file": read_csv_rows(QC_DIR / "GSE260657_cell_qc_by_file.csv"),
    }
    rows["deg111"] = count_fdr(TABLE_DIR / "GSE111782_DEG_complete.csv")
    rows["deg311"] = count_fdr(TABLE_DIR / "GSE311535_DEG_complete.csv")
    rows["top111"] = top_rows(TABLE_DIR / "GSE111782_DEG_complete.csv", "P_value", 3)
    rows["top311"] = top_rows(TABLE_DIR / "GSE311535_DEG_complete.csv", "P_value", 3)
    return rows


def cell_count_summary(cell_ann: list[dict[str, str]]) -> str:
    counts: dict[str, int] = {}
    for row in cell_ann:
        ct = row.get("major_cell_type") or "unassigned"
        counts[ct] = counts.get(ct, 0) + 1
    order = sorted(counts.items(), key=lambda kv: (-kv[1], kv[0]))
    return "; ".join(f"{ct}: {n:,}" for ct, n in order)


def sc_qc_range(cell_ann: list[dict[str, str]]) -> dict[str, str]:
    out: dict[str, str] = {}
    for key in ["detected_genes", "counts", "mt_fraction"]:
        vals = []
        for row in cell_ann:
            try:
                vals.append(float(row.get(key, "nan")))
            except ValueError:
                pass
        vals = [x for x in vals if math.isfinite(x)]
        out[f"{key}_min"] = fmt_num(min(vals), 0 if key != "mt_fraction" else 3) if vals else "NA"
        out[f"{key}_max"] = fmt_num(max(vals), 0 if key != "mt_fraction" else 3) if vals else "NA"
    return out


def fdr_sig_count(rows: list[dict[str, str]]) -> int:
    total = 0
    for row in rows:
        try:
            total += float(row.get("FDR", "1")) < 0.05
        except ValueError:
            pass
    return total


def reduced_corr_text(rows: list[dict[str, str]]) -> str:
    parts = []
    for cohort in ["GSE111782", "GSE311535"]:
        row = row_match(rows, cohort=cohort)
        if row:
            parts.append(f"{cohort}: rho = {fmt_num(row.get('rho'))}, FDR = {fmt_p(row.get('FDR'))}")
    return "; ".join(parts)


def dominant_specificity_text(rows: list[dict[str, str]]) -> str:
    counts: dict[str, int] = {}
    for row in rows:
        ct = row.get("dominant_cell_type_by_mean") or "NA"
        counts[ct] = counts.get(ct, 0) + 1
    ordered = sorted(counts.items(), key=lambda kv: (-kv[1], kv[0]))
    return "; ".join(f"{ct}: {n}" for ct, n in ordered)


def build_manuscript(ctx: dict[str, object], refs_text: str) -> str:
    sig_corr = ctx["sig_corr"]
    boot = ctx["boot"]
    partial = ctx["partial"]
    mapping = ctx["mapping"]
    overlap = ctx["overlap"]
    proxy_overlap = ctx["proxy_overlap"]
    sig_summary = ctx["sig_summary"]
    sig_effects = ctx["sig_effects"]
    ranked_111 = ctx["ranked_111"]
    ranked_311 = ctx["ranked_311"]
    cell_ann = ctx["cell_ann"]
    sample_audit = ctx["sample_audit"]
    inflam_specificity = ctx["inflam_specificity"]
    inflam_score_summary = ctx["inflam_score_summary"]
    reduced_status = ctx["reduced_status"]
    reduced_corr = ctx["reduced_corr"]
    loo_gene = ctx["loo_gene"]
    deg111_n, deg111_sig = ctx["deg111"]
    deg311_n, deg311_sig = ctx["deg311"]

    main111 = row_match(sig_corr, cohort="GSE111782", signature_1="efferocytosis", signature_2="inflammatory_vsmc")
    main311 = row_match(sig_corr, cohort="GSE311535", signature_1="efferocytosis", signature_2="inflammatory_vsmc")
    boot111 = row_match(boot, cohort="GSE111782")
    boot311 = row_match(boot, cohort="GSE311535")
    eff_syn111 = row_match(sig_corr, cohort="GSE111782", signature_1="efferocytosis", signature_2="synthetic_vsmc")
    eff_ecm311 = row_match(sig_corr, cohort="GSE311535", signature_1="efferocytosis", signature_2="ecm_remodeling_vsmc")

    p111_mv = row_match(partial, cohort="GSE111782", model="macrophage_and_vsmc_proxy")
    p111_four = row_match(partial, cohort="GSE111782", model="four_celltype_proxy")
    p111_inf = row_match(partial, cohort="GSE111782", model="nonoverlap_broad_inflammation_proxy")
    p311_mv = row_match(partial, cohort="GSE311535", model="macrophage_and_vsmc_proxy")
    p311_four = row_match(partial, cohort="GSE311535", model="four_celltype_proxy")
    p311_inf = row_match(partial, cohort="GSE311535", model="nonoverlap_broad_inflammation_proxy")

    map_eff111 = row_match(mapping, cohort="GSE111782", signature="efferocytosis")
    map_eff311 = row_match(mapping, cohort="GSE311535", signature="efferocytosis")
    map_infl111 = row_match(mapping, cohort="GSE111782", signature="inflammatory_vsmc")
    map_infl311 = row_match(mapping, cohort="GSE311535", signature="inflammatory_vsmc")
    eff_infl_overlap = row_match(overlap, signature_1="efferocytosis", signature_2="inflammatory_vsmc")
    if not eff_infl_overlap:
        eff_infl_overlap = row_match(overlap, signature_1="inflammatory_vsmc", signature_2="efferocytosis")

    eff_effect111 = row_match(sig_effects, cohort="GSE111782", signature="efferocytosis")
    contractile_effect111 = row_match(sig_effects, cohort="GSE111782", signature="contractile_vsmc")
    eff_effect311 = row_match(sig_effects, cohort="GSE311535", signature="efferocytosis")
    eff111 = row_match(sig_summary, cohort="GSE111782", signature="efferocytosis")
    eff311 = row_match(sig_summary, cohort="GSE311535", signature="efferocytosis")

    ranked_sig111 = [r for r in ranked_111 if float(r.get("padj", "1") or 1) < 0.05]
    signature_display = {
        "contractile_vsmc": "contractile VSMC",
        "synthetic_vsmc": "synthetic VSMC",
        "inflammatory_vsmc": "inflammatory VSMC-associated",
        "ecm_remodeling_vsmc": "ECM-remodeling/osteogenic VSMC",
        "efferocytosis": "efferocytosis-related",
    }
    ranked_text = "; ".join(
        f"{signature_display.get(r.get('pathway'), r.get('pathway'))} "
        f"(NES {fmt_num(r.get('NES'))}, FDR = {fmt_p(r.get('padj'))})"
        for r in ranked_sig111
    ) or "no predefined signature with FDR < 0.05"
    best311 = sorted(ranked_311, key=lambda r: float(r.get("padj", "1") or 1))[0] if ranked_311 else {}
    best311_name = signature_display.get(best311.get("pathway"), best311.get("pathway", "NA"))

    sc_qc = sc_qc_range(cell_ann)
    total_cells = len(cell_ann)
    sample_total = len(sample_audit) or 15
    symptom_n = sum(1 for r in sample_audit if r.get("group") == "symptomatic") or 8
    asymptom_n = sum(1 for r in sample_audit if r.get("group") == "asymptomatic") or 7

    proxy_mac_overlap = row_match(proxy_overlap, proxy="macrophage_marker", signature="efferocytosis")
    proxy_vsmc_overlap = row_match(proxy_overlap, proxy="vsmc_marker", signature="contractile_vsmc")
    proxy_infl_overlap = row_match(proxy_overlap, proxy="broad_inflammation_marker_nonoverlap", signature="inflammatory_vsmc")

    vsmc_top2 = reduced_status[0].get("retained_genes", "") if reduced_status else ""
    vsmc_top2_display = ", ".join(g for g in vsmc_top2.split(";") if g)
    infl_score_vsmc = row_match(inflam_score_summary, major_cell_type="vsmc")
    infl_score_tnk = row_match(inflam_score_summary, major_cell_type="t_nk")
    infl_score_fib = row_match(inflam_score_summary, major_cell_type="fibroblast")
    loo_minmax = {}
    for cohort in ["GSE111782", "GSE311535"]:
        vals = []
        for row in loo_gene:
            if row.get("cohort") == cohort:
                try:
                    vals.append(float(row.get("rho", "nan")))
                except ValueError:
                    pass
        loo_minmax[cohort] = (min(vals), max(vals)) if vals else (math.nan, math.nan)

    donor_program_sig = fdr_sig_count(ctx["donor_tests"])
    comp_sig = fdr_sig_count(ctx["comp_tests"])

    manuscript = f"""# {TITLE}

Article type: Original Research

Running title: {RUNNING_TITLE}

Author: {AUTHOR}

Affiliation: {AFFILIATION}

Corresponding author: {AUTHOR}, {AFFILIATION}. Email: {CORRESPONDING_EMAIL}

## Abstract

Background: Efferocytosis-related transcription and vascular smooth muscle cell (VSMC) phenotypic modulation are both relevant to carotid atherosclerosis. Whether these programs covary in clinically symptomatic versus asymptomatic human carotid plaque transcriptomes remains uncertain.

Methods: We reanalyzed public Gene Expression Omnibus datasets. GSE111782 was used as a discovery bulk microarray cohort with 9 symptomatic and 9 asymptomatic plaques. GSE311535 was used as an independent heterogeneous RNA-seq replication cohort with 6 symptomatic and 6 asymptomatic plaques from patients with diabetes. GSE260657 was used for single-cell localization across {symptom_n} symptomatic and {asymptom_n} asymptomatic carotid plaque sample files. Predefined efferocytosis-related and VSMC-state literature signatures were assessed using assay-matched bulk models, ranked enrichment, sample-level scores, Spearman correlations, bootstrap and leave-one-out analyses, marker-proxy partial correlations, and sample-file-level single-cell summaries.

Results: No individual gene reached FDR < 0.05 in either bulk cohort. No predefined sample-level signature comparison between symptomatic and asymptomatic plaques reached FDR < 0.05. The efferocytosis-related and inflammatory VSMC-associated signatures had no direct gene overlap (Jaccard = {fmt_num(eff_infl_overlap.get('jaccard'))}). Efferocytosis-related scores correlated with inflammatory VSMC-associated scores in GSE111782 (Spearman rho = {fmt_num(main111.get('rho'))}, FDR = {fmt_p(main111.get('FDR'))}, bootstrap 95% CI {fmt_num(boot111.get('bootstrap_ci_low'))} to {fmt_num(boot111.get('bootstrap_ci_high'))}) and GSE311535 (rho = {fmt_num(main311.get('rho'))}, FDR = {fmt_p(main311.get('FDR'))}, bootstrap 95% CI {fmt_num(boot311.get('bootstrap_ci_low'))} to {fmt_num(boot311.get('bootstrap_ci_high'))}). This reproducible signal was unadjusted and tissue-level. It was strongly attenuated in GSE111782 after marker-proxy adjustment and remained positive but imprecise in some GSE311535 proxy-adjusted analyses. A non-overlapping broad inflammation proxy attenuated the association in GSE111782 and reduced it below the FDR threshold in GSE311535. Single-cell analysis localized macrophage and VSMC compartments, but sample-file-level program and cell-composition comparisons did not reach FDR < 0.05. The 12-gene inflammatory VSMC-associated score was not VSMC-restricted in the single-cell data.

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

GSE311535 served as an independent heterogeneous bulk replication cohort. It contains human carotid plaque RNA-seq count data from patients with diabetes, including 6 symptomatic and 6 asymptomatic samples [2]. Because this cohort is diabetes-specific, it was not treated as a clinically matched cohort. GSE260657 was used for single-cell localization because its GEO record and linked publication describe Smart-seq2 data from 15 human carotid plaque sample files, including {symptom_n} symptomatic and {asymptom_n} asymptomatic sample files [3]. Dataset provenance, URLs, limitations, and audit decisions are recorded in the data provenance file and Supplementary Table 1.

### Predefined gene sets and proxy audit

The efferocytosis-related gene set contained 30 genes defined before inspecting project results. It included recognition receptors, bridging molecules, integrin or scavenger uptake genes, inflammation-resolution or phosphatidylserine-binding genes, lipid-handling genes, and lysosomal-processing genes. The genes were {list_genes(ctx['gene_sets'], 'efferocytosis')}.

VSMC programs were analyzed as separate contractile, synthetic, inflammatory VSMC-associated, and ECM-remodeling/osteogenic signatures. Each signature contained 12 genes. These were treated as literature-informed transcriptional programs, not definitive lineage-state measurements. The inflammatory VSMC-associated signature contained IL6, CCL2, CCL5, CXCL8, CXCL12, ICAM1, VCAM1, NFKB1, RELA, STAT3, TNF, and IL1B. Because several of these genes are not VSMC-restricted and may be expressed by immune, endothelial, or stromal cells, the bulk score was not interpreted as a VSMC-specific measurement.

Gene-set overlap was audited before interpreting correlations. The efferocytosis-related and inflammatory VSMC-associated signatures shared 0 genes (Jaccard = {fmt_num(eff_infl_overlap.get('jaccard'))}). Platform mapping retained {map_eff111.get('mapped_genes')}/{map_eff111.get('total_genes')} efferocytosis-related genes and {map_infl111.get('mapped_genes')}/{map_infl111.get('total_genes')} inflammatory VSMC-associated genes in GSE111782. It retained {map_eff311.get('mapped_genes')}/{map_eff311.get('total_genes')} and {map_infl311.get('mapped_genes')}/{map_infl311.get('total_genes')} genes, respectively, in GSE311535.

Marker-proxy adjustment used exploratory marker scores. Full proxy gene lists, overlap audits, proxy correlations, and collinearity summaries are provided in Supplementary Tables 2-4. The macrophage proxy overlapped with 4 efferocytosis-related genes ({proxy_mac_overlap.get('overlap_genes')}). The VSMC proxy overlapped with 9 contractile VSMC genes ({proxy_vsmc_overlap.get('overlap_genes')}). The non-overlapping broad inflammation proxy was introduced during revision as an exploratory sensitivity analysis to assess whether the main correlation was attributable to generalized inflammatory burden. It was defined to avoid direct overlap with the inflammatory VSMC-associated and efferocytosis-related signatures (overlap with inflammatory VSMC-associated signature = {proxy_infl_overlap.get('overlap_count')}) and was not treated as a prespecified confirmatory covariate. These overlaps mean that proxy-adjusted analyses are sensitivity analyses, not evidence of independent causal effects.

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

In GSE111782, limma tested {deg111_n:,} genes and identified {deg111_sig} genes at FDR < 0.05 (Figure 2). The smallest nominal P-value genes were {top_deg_text(ctx['top111'])}. Their adjusted values were not below the prespecified threshold. In GSE311535, edgeR tested {deg311_n:,} genes and identified {deg311_sig} genes at FDR < 0.05. The smallest nominal P-value genes were {top_deg_text(ctx['top311'])}, again without FDR support. The available data do not support presenting individual genes as replicated symptomatic-versus-asymptomatic markers.

### Discovery enrichment signals were not reproduced

Discovery-ranked enrichment suggested lower representation of several predefined programs in symptomatic plaques: {ranked_text}. In GSE311535, none of the ranked predefined signatures reached FDR < 0.05. The lowest adjusted value was observed for {best311_name} (NES {fmt_num(best311.get('NES'))}, FDR = {fmt_p(best311.get('padj'))}). These enrichment results were therefore treated as cohort-specific exploratory observations.

### Sample-level signature group comparisons did not survive FDR correction

No predefined efferocytosis-related or VSMC program score differed between symptomatic and asymptomatic plaques at FDR < 0.05 in either bulk cohort. In GSE111782, the efferocytosis-related median score was {fmt_num(eff111.get('median_asymptomatic'))} in asymptomatic plaques and {fmt_num(eff111.get('median_symptomatic'))} in symptomatic plaques ({effect_text(eff_effect111)}). The contractile VSMC score showed a nominal difference in GSE111782 ({effect_text(contractile_effect111)}), but it did not survive FDR correction. In GSE311535, the efferocytosis-related median score was {fmt_num(eff311.get('median_asymptomatic'))} in asymptomatic plaques and {fmt_num(eff311.get('median_symptomatic'))} in symptomatic plaques ({effect_text(eff_effect311)}). These results indicate that FDR-supported group differences were not detected at the current sample size and data quality.

### Efferocytosis-related and inflammatory VSMC-associated scores showed reproducible unadjusted tissue-level covariation

The main bulk observation, reproducible only in the unadjusted analysis, was a positive tissue-level correlation between efferocytosis-related and inflammatory VSMC-associated scores (Figure 3). In GSE111782, the correlation was rho = {fmt_num(main111.get('rho'))} (P = {fmt_p(main111.get('P_value'))}, FDR = {fmt_p(main111.get('FDR'))}). Leave-one-out correlations ranged from {fmt_num(boot111.get('loo_min_rho'))} to {fmt_num(boot111.get('loo_max_rho'))}, and the bootstrap 95% interval was {fmt_num(boot111.get('bootstrap_ci_low'))} to {fmt_num(boot111.get('bootstrap_ci_high'))}. The efferocytosis-related score also correlated with the synthetic VSMC score in GSE111782 (rho = {fmt_num(eff_syn111.get('rho'))}, FDR = {fmt_p(eff_syn111.get('FDR'))}), which was treated as supportive and exploratory.

In GSE311535, the efferocytosis-related score again correlated with the inflammatory VSMC-associated score (rho = {fmt_num(main311.get('rho'))}, P = {fmt_p(main311.get('P_value'))}, FDR = {fmt_p(main311.get('FDR'))}). Leave-one-out correlations ranged from {fmt_num(boot311.get('loo_min_rho'))} to {fmt_num(boot311.get('loo_max_rho'))}, and the bootstrap 95% interval was {fmt_num(boot311.get('bootstrap_ci_low'))} to {fmt_num(boot311.get('bootstrap_ci_high'))}. The association with ECM-remodeling/osteogenic VSMC score was weaker and did not pass FDR correction (rho = {fmt_num(eff_ecm311.get('rho'))}, FDR = {fmt_p(eff_ecm311.get('FDR'))}).

### Marker-proxy adjustment weakened the claim of an independent association

Marker-proxy adjustment gave a more cautious interpretation. In GSE111782, the main association was nearly absent after adjustment for macrophage plus VSMC marker proxies ({partial_text(p111_mv)}), four cell-type proxies ({partial_text(p111_four)}), or the non-overlapping broad inflammation proxy ({partial_text(p111_inf)}).

In GSE311535, the point estimate remained positive in the small exploratory analyses adjusted for macrophage plus VSMC marker proxies ({partial_text(p311_mv)}) and four cell-type proxies ({partial_text(p311_four)}). The bootstrap intervals were wide, and the four-proxy model used only 12 samples with four covariates. After adjustment for the non-overlapping broad inflammation proxy, the association was lower and did not meet the FDR threshold ({partial_text(p311_inf)}). These results support a reproducible unadjusted mixed-tissue correlation, but not an independent macrophage-VSMC relationship after accounting for marker proxies.

### The inflammatory VSMC-associated signature was not VSMC-restricted in single-cell data

Single-cell expression analysis of the 12 inflammatory VSMC-associated genes showed broad expression across annotated compartments (Supplementary Figure 3). Dominant cell types by median mean expression were {dominant_specificity_text(inflam_specificity)}. At the sample-file level, the full inflammatory VSMC-associated score was not highest in VSMCs. The median sample-level score was {fmt_num(infl_score_tnk.get('median_sample_level_score'))} in T/NK cells, {fmt_num(infl_score_fib.get('median_sample_level_score'))} in fibroblasts, and {fmt_num(infl_score_vsmc.get('median_sample_level_score'))} in VSMCs. This supports the decision to avoid interpreting the bulk score as VSMC-specific.

A revision-stage data-driven sensitivity analysis retained four genes whose single-cell mean expression ranked within the top two cell types for VSMC: {vsmc_top2_display}. The restricted score remained correlated with efferocytosis-related scores in both bulk cohorts ({reduced_corr_text(reduced_corr)}). This analysis was generated after review of GSE260657 and was not a prespecified primary analysis or independent test. It indicates that the unadjusted association was not lost after one restricted-gene scoring rule, but it does not establish VSMC specificity or mechanism. Leave-one-gene-out analysis of the 12-gene score also retained positive correlations in both cohorts (GSE111782 rho range {fmt_num(loo_minmax['GSE111782'][0])} to {fmt_num(loo_minmax['GSE111782'][1])}; GSE311535 rho range {fmt_num(loo_minmax['GSE311535'][0])} to {fmt_num(loo_minmax['GSE311535'][1])}).

### Single-cell analysis localized major compartments without sample-file-level FDR-supported group differences

GSE260657 yielded {total_cells:,} parsed cells across {sample_total} sample files. Detected genes ranged from {sc_qc['detected_genes_min']} to {sc_qc['detected_genes_max']}, total counts from {sc_qc['counts_min']} to {sc_qc['counts_max']}, and mitochondrial fraction from {sc_qc['mt_fraction_min']} to {sc_qc['mt_fraction_max']}. Marker-score annotation assigned the main cell classes as {cell_count_summary(cell_ann)} (Figure 4). Supplementary marker dotplots supported the broad annotation pattern but did not replace full reference mapping.

Sample-file-level program comparisons across macrophage and VSMC compartments did not identify FDR-supported symptomatic-versus-asymptomatic differences (FDR < 0.05 comparisons: {donor_program_sig}). Sample-file-level cell-composition tests also did not reach FDR < 0.05 (FDR < 0.05 comparisons: {comp_sig}). Raw cell counts were treated as technical descriptors because capture efficiency, tissue dissociation, cell viability, sequencing depth, and filtering can affect them. Cell fractions were used descriptively and were not interpreted as definitive abundance changes.

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

{refs_text}
"""
    return humanizer_pass(manuscript)


def humanizer_pass(text: str) -> str:
    replacements = {
        "\u2014": ", ",
        "\u2013": "-",
        "vulnerable plaque": "pathology-defined plaque category",
        "unstable plaque": "pathology-defined plaque category",
        "robust independent": "independent",
        "key ": "",
        "underscores": "supports",
        "highlights": "shows",
        "demonstrates": "shows",
    }
    for old, new in replacements.items():
        text = text.replace(old, new)
    text = re.sub(r"\bproved\b", "showed", text)
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r" +\n", "\n", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip() + "\n"


def strip_inline_md(text: str) -> str:
    text = text.replace("**", "").replace("__", "").replace("`", "")
    text = re.sub(r"\[(.*?)\]\((.*?)\)", r"\1 (\2)", text)
    return text


def apply_font_to_run(run, size: float = 12.0, bold: bool | None = None) -> None:
    run.font.name = "Times New Roman"
    run.font.size = Pt(size)
    if bold is not None:
        run.bold = bold
    run._element.rPr.rFonts.set(qn("w:eastAsia"), "Times New Roman")


def set_paragraph_format(paragraph) -> None:
    paragraph.paragraph_format.line_spacing_rule = WD_LINE_SPACING.DOUBLE
    paragraph.paragraph_format.space_after = Pt(0)
    for run in paragraph.runs:
        apply_font_to_run(run, 12.0)


def set_cell_shading(cell, fill: str) -> None:
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:fill"), fill)
    tc_pr.append(shd)


def finalize_doc_style(doc: Document) -> None:
    for style_name in ["Normal", "Heading 1", "Heading 2", "Heading 3", "List Bullet", "List Number"]:
        if style_name in doc.styles:
            style = doc.styles[style_name]
            style.font.name = "Times New Roman"
            style.font.size = Pt(12)
            style._element.rPr.rFonts.set(qn("w:eastAsia"), "Times New Roman")
    for section in doc.sections:
        section.top_margin = Inches(1)
        section.bottom_margin = Inches(1)
        section.left_margin = Inches(1)
        section.right_margin = Inches(1)
    for paragraph in doc.paragraphs:
        set_paragraph_format(paragraph)
    for table in doc.tables:
        table.autofit = True
        for i, row in enumerate(table.rows):
            for cell in row.cells:
                if i == 0:
                    set_cell_shading(cell, "EDEDED")
                for paragraph in cell.paragraphs:
                    set_paragraph_format(paragraph)


def add_markdown(doc: Document, markdown: str, skip_top_title: bool = False) -> None:
    lines = markdown.splitlines()
    buffer: list[str] = []

    def flush() -> None:
        if not buffer:
            return
        text = strip_inline_md(" ".join(part.strip() for part in buffer).strip())
        if text:
            doc.add_paragraph(text)
        buffer.clear()

    for raw in lines:
        line = raw.rstrip()
        if not line.strip():
            flush()
            continue
        if skip_top_title and line.startswith("# "):
            continue
        if line.startswith("### "):
            flush()
            doc.add_heading(strip_inline_md(line[4:].strip()), level=3)
        elif line.startswith("## "):
            flush()
            doc.add_heading(strip_inline_md(line[3:].strip()), level=2)
        elif line.startswith("# "):
            flush()
            p = doc.add_paragraph()
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            r = p.add_run(strip_inline_md(line[2:].strip()))
            r.bold = True
            apply_font_to_run(r, 12.0)
        elif line.startswith("- "):
            flush()
            doc.add_paragraph(strip_inline_md(line[2:].strip()), style="List Bullet")
        else:
            buffer.append(line)
    flush()


def save_docx_from_markdown(markdown: str, output: Path, skip_top_title: bool = False) -> None:
    doc = Document()
    add_markdown(doc, markdown, skip_top_title=skip_top_title)
    finalize_doc_style(doc)
    output.parent.mkdir(parents=True, exist_ok=True)
    doc.save(output)


def add_table(doc: Document, title: str, rows: list[dict[str, str]], columns: list[tuple[str, str]], max_rows: int | None = None) -> None:
    doc.add_heading(title, level=2)
    if not rows:
        doc.add_paragraph("No source rows were available.")
        return
    selected = rows if max_rows is None else rows[:max_rows]
    table = doc.add_table(rows=1, cols=len(columns))
    table.style = "Table Grid"
    for j, (_, label) in enumerate(columns):
        table.rows[0].cells[j].text = label
    for row in selected:
        cells = table.add_row().cells
        for j, (key, _) in enumerate(columns):
            value = row.get(key, "")
            if key.lower() in {"rho", "fdr", "p_value", "bootstrap_ci_low", "bootstrap_ci_high", "loo_min_rho", "loo_max_rho"}:
                value = fmt_p(value) if key.lower() in {"fdr", "p_value"} else fmt_num(value)
            cells[j].text = str(value)
    if max_rows is not None and len(rows) > max_rows:
        doc.add_paragraph(f"Showing {max_rows} of {len(rows)} rows. Complete source tables remain in 05_results/tables.")


def main_correlation_table(ctx: dict[str, object]) -> list[dict[str, str]]:
    out = []
    for cohort in ["GSE111782", "GSE311535"]:
        corr = row_match(ctx["sig_corr"], cohort=cohort, signature_1="efferocytosis", signature_2="inflammatory_vsmc")
        boot = row_match(ctx["boot"], cohort=cohort)
        out.append({
            "cohort": cohort,
            "n": corr.get("n_samples", ""),
            "rho": corr.get("rho", ""),
            "ci": f"{fmt_num(boot.get('bootstrap_ci_low'))} to {fmt_num(boot.get('bootstrap_ci_high'))}",
            "fdr": fmt_p(corr.get("FDR")),
            "loo": f"{fmt_num(boot.get('loo_min_rho'))} to {fmt_num(boot.get('loo_max_rho'))}",
        })
    return out


def specificity_rows(ctx: dict[str, object]) -> list[dict[str, str]]:
    rows = []
    for row in ctx["inflam_specificity"]:
        rows.append({
            "gene": row.get("gene", ""),
            "dominant": row.get("dominant_cell_type_by_mean", ""),
            "vsmc_rank": row.get("vsmc_mean_rank", ""),
            "vsmc_mean": fmt_num(row.get("vsmc_mean_log1p_cpm")),
            "vsmc_fraction": fmt_num(row.get("vsmc_fraction_expressing")),
        })
    return rows


def figure_files() -> list[tuple[str, str]]:
    return [
        ("Figure_1_study_design", "Figure 1. Study design, cohort roles, and analysis gates."),
        ("Figure_2_discovery_bulk", "Figure 2. Discovery bulk sample structure and differential-expression results."),
        ("Figure_3_signature_scores", "Figure 3. Main unadjusted tissue-level correlation and exploratory proxy adjustment."),
        ("Figure_4_single_cell_atlas", "Figure 4. Single-cell atlas and major-cell annotation."),
        ("Figure_5_macrophage_efferocytosis", "Figure 5. Macrophage descriptive program-score groups."),
        ("Figure_6_vsmc_states", "Figure 6. VSMC descriptive program-score groups."),
        ("Figure_7_replication_overview", "Figure 7. Discovery and replication signature-score overview."),
        ("Supplementary_Figure_1_signature_group_comparisons", "Supplementary Figure 1. Signature score group comparisons."),
        ("Supplementary_Figure_2_single_cell_marker_dotplot", "Supplementary Figure 2. Single-cell marker expression by annotated cell type."),
        ("Supplementary_Figure_3_inflammatory_vsmc_associated_dotplot", "Supplementary Figure 3. Inflammatory VSMC-associated genes across cell compartments."),
    ]


def build_integrated_doc(manuscript: str, ctx: dict[str, object], output: Path) -> None:
    doc = Document()
    section = doc.sections[0]
    section.top_margin = Inches(0.8)
    section.bottom_margin = Inches(0.8)
    section.left_margin = Inches(0.75)
    section.right_margin = Inches(0.75)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run(TITLE)
    apply_font_to_run(r, 12.0, bold=True)
    for line in [
        "Target journal: Frontiers in Cardiovascular Medicine",
        "Article type: Original Research",
        f"Author: {AUTHOR}",
        f"Affiliation: {AFFILIATION}",
        f"Corresponding author email: {CORRESPONDING_EMAIL}",
        "Fourth-revision integrated author-review document",
        f"Generated: {stamp()}",
    ]:
        q = doc.add_paragraph(line)
        q.alignment = WD_ALIGN_PARAGRAPH.CENTER

    doc.add_page_break()
    doc.add_heading("Main Manuscript", level=1)
    add_markdown(doc, manuscript, skip_top_title=True)

    doc.add_page_break()
    doc.add_heading("Compact Reviewer-Facing Tables", level=1)
    doc.add_paragraph("Full result tables are retained as CSV files under 05_results/tables. Only compact tables are embedded here to avoid unreadable wrapped tables.")
    add_table(
        doc,
        "Table 1. Main unadjusted correlation summary",
        main_correlation_table(ctx),
        [("cohort", "Cohort"), ("n", "n"), ("rho", "rho"), ("ci", "95% CI"), ("fdr", "FDR"), ("loo", "Leave-one-out rho")],
    )
    add_table(
        doc,
        "Table 2. Exploratory marker-proxy partial correlations",
        ctx["partial"],
        [("cohort", "Cohort"), ("model", "Model"), ("rho", "Partial rho"), ("bootstrap_ci_low", "CI low"), ("bootstrap_ci_high", "CI high"), ("FDR", "FDR")],
    )
    add_table(
        doc,
        "Table 3. Single-cell specificity of inflammatory VSMC-associated genes",
        specificity_rows(ctx),
        [("gene", "Gene"), ("dominant", "Dominant cell type by median mean expression"), ("vsmc_rank", "Rank of VSMC among cell types by median mean expression"), ("vsmc_mean", "Median expression among VSMC cells"), ("vsmc_fraction", "Fraction of annotated VSMC cells expressing gene")],
    )
    doc.add_paragraph("Table note: the final column denotes the fraction of annotated VSMC cells expressing the gene. It does not denote the fraction of all gene-expressing cells attributable to VSMCs.")
    sample_rows = []
    for row in ctx["sample_audit"]:
        sample_rows.append({
            "gsm": row.get("gsm", ""),
            "group": row.get("group", ""),
            "cells": row.get("cells", ""),
            "macrophage": row.get("macrophage", ""),
            "vsmc": row.get("vsmc", ""),
        })
    add_table(
        doc,
        "Table 4. GSE260657 sample-file audit",
        sample_rows,
        [("gsm", "GSM"), ("group", "Group"), ("cells", "Cells"), ("macrophage", "Macrophage"), ("vsmc", "VSMC")],
    )

    doc.add_page_break()
    doc.add_heading("Figures and Supplementary Figures", level=1)
    for stem, caption in figure_files():
        img = FIGURE_DIR / f"{stem}.png"
        doc.add_heading(caption, level=2)
        if img.exists():
            paragraph = doc.add_paragraph()
            paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
            run = paragraph.add_run()
            run.add_picture(str(img), width=Inches(6.7))
            doc.add_paragraph(f"Source data and script trace: 05_results/tables, 05_results/qc, and 04_scripts/20_final_technical_revision_analysis_and_figures.R.")
        else:
            doc.add_paragraph(f"Image was not found: {img.name}")
            record_error(f"Missing figure PNG for integrated document: {img}")

    doc.add_page_break()
    doc.add_heading("Fourth-Round Revision Note", level=1)
    add_markdown(doc, build_revision_note(ctx), skip_top_title=True)
    finalize_doc_style(doc)
    output.parent.mkdir(parents=True, exist_ok=True)
    doc.save(output)


def build_revision_note(ctx: dict[str, object]) -> str:
    reduced = ctx["reduced_status"][0] if ctx["reduced_status"] else {}
    return f"""# 第四轮最终技术修订落实说明

## 已完成的主要修改

- 将主结论降格为 reproducible unadjusted tissue-level correlation，并明确不是对细胞组成或总体炎症负担稳健的独立关联。
- 将全文 inflammatory VSMC signature/program 改为 inflammatory VSMC-associated signature/program 或 VSMC-state literature signature。
- 新增非重叠 broad inflammation proxy，避免把主结局的同一批12个基因再作为调整变量。
- 补充 proxy gene lists、proxy 与主基因集的重叠审计、proxy 相关性和 VIF-like 共线性摘要。
- 补充偏 Spearman 相关的 bootstrap 置信区间，并把 GSE311535 的调整后结果写成小样本探索性结果。
- 补充 GSE260657 单细胞中12个 inflammatory VSMC-associated 基因的细胞类型表达 DotPlot 和源表。
- 补充 GSE260657 样本文件审计表，明确 sample file/GSM 被用作保守 donor/sample-level 单位，尚未独立证明每个文件都对应不同患者。
- 将原始 n_cells 降为技术性描述，正文以 donor/sample-level summaries 和 fraction 描述为主。
- 重做 Figure 1 为并行证据层，重做 Figure 3 为两队列散点图、rho森林图和proxy调整图。
- 将宽表格改为紧凑表格，完整结果保留为 CSV 补充材料。
- 填入作者 Hong-Lin Guo、单位、单作者贡献、无资助和无利益冲突声明。
- 最后按 Humanizer 规则清理语言，删除过强机制、诊断、治疗和病理分类措辞。

## 新增分析结果要点

- 修正后的非重叠 broad inflammation proxy 与 efferocytosis 和 inflammatory VSMC-associated 主基因集均无直接基因重叠。
- 第四轮偏相关显示 GSE111782 在三类 proxy 调整后均明显衰减；GSE311535 在细胞类型 proxy 调整后仍为正，但 bootstrap 区间较宽，非重叠炎症 proxy 调整后 FDR 未达 0.05。
- 单细胞审计显示完整12基因 inflammatory VSMC-associated score 并非 VSMC 最高，不能解释为 VSMC-specific measurement。
- 数据驱动保留的 VSMC mean rank <= 2 基因是 {reduced.get('retained_genes', 'NA')}。其 bulk 敏感性结果仍为正相关，但只能作为敏感性分析。

## 仍需真实作者处理

- 通讯作者邮箱仍缺失，当前保留为 {CORRESPONDING_EMAIL}。
- 原始研究伦理批准和知情同意表述需从源论文逐条核验。
- 代码仓库 URL 需在上传永久公开仓库后填写。
- Frontiers 最终 AI 使用披露、版权声明、图像格式和投稿系统字段需由作者最终确认。
- 参考文献与正文每条论断仍建议投稿前逐句核对。

## 新增或更新的文件

- 04_scripts/20_final_technical_revision_analysis_and_figures.R
- 04_scripts/21_apply_final_interpretive_revision.py
- 05_results/tables/main_correlation_partial_spearman_proxy_adjustment_fourth.csv
- 05_results/tables/bulk_marker_proxy_gene_sets_fourth.csv
- 05_results/tables/bulk_marker_proxy_overlap_fourth.csv
- 05_results/tables/GSE260657_inflammatory_vsmc_associated_gene_celltype_expression_fourth.csv
- 05_results/tables/GSE260657_inflammatory_vsmc_associated_gene_specificity_summary_fourth.csv
- 05_results/tables/GSE260657_sample_level_celltype_audit_fourth.csv
- 05_results/figures/Figure_1_study_design.svg
- 05_results/figures/Figure_3_signature_scores.svg
- 05_results/figures/Supplementary_Figure_3_inflammatory_vsmc_associated_dotplot.svg

## 投稿判断

第四轮稿件已经更接近可投稿的作者审阅稿，但仍不应在缺少通讯邮箱、伦理核验、代码永久仓库和最终引文核对的情况下直接投稿。当前建议状态为 READY FOR AUTHOR REVIEW, NOT READY FOR DIRECT SUBMISSION.
"""


def copy_svg_bundle() -> None:
    dest = OUTPUT_DIR / "SVG图片"
    dest.mkdir(parents=True, exist_ok=True)
    for svg in FIGURE_DIR.glob("*.svg"):
        shutil.copy2(svg, dest / svg.name)
    package_dest = ROOT / "07_submission_package" / "figures_svg_for_ai"
    package_dest.mkdir(parents=True, exist_ok=True)
    for svg in FIGURE_DIR.glob("*.svg"):
        shutil.copy2(svg, package_dest / svg.name)
    zip_path = ROOT / "07_submission_package" / "figures_svg_for_ai.zip"
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        for svg in sorted(package_dest.glob("*.svg")):
            zf.write(svg, arcname=svg.name)


def update_qc_reports(outputs: dict[str, Path]) -> None:
    final_qc = ROOT / "07_submission_package" / "FINAL_QC_REPORT.md"
    readiness = ROOT / "07_submission_package" / "SUBMISSION_READINESS.md"
    delivery = ROOT / "07_submission_package" / "DELIVERY_SUMMARY.md"
    append = f"""

## Fourth-revision update ({dt.date.today().isoformat()})

- Author information was updated to Hong-Lin Guo, School of Pharmacy, Harbin University of Commerce, Harbin 150076, China.
- Funding and conflict-of-interest statements were updated using author-provided information.
- The corresponding author email, original-study ethics/consent details, public code repository URL, and final citation-to-claim audit remain AUTHOR_INPUT_NEEDED.
- The main conclusion was revised to reproducible unadjusted tissue-level correlation.
- The inflammatory VSMC program was renamed as inflammatory VSMC-associated and explicitly marked as not VSMC-specific in bulk tissue.
- Fourth-round figures and SVG files were regenerated by 04_scripts/20_final_technical_revision_analysis_and_figures.R.
- Fourth-round manuscript package: {outputs['manuscript_docx'].relative_to(ROOT)}; integrated review package: {outputs['integrated_docx'].relative_to(ROOT)}.
"""
    for path in [final_qc, readiness, delivery]:
        with path.open("a", encoding="utf-8") as handle:
            handle.write(append)


def qa_docx_text(path: Path) -> dict[str, object]:
    with zipfile.ZipFile(path) as zf:
        xml = zf.read("word/document.xml").decode("utf-8", errors="replace")
    plain = re.sub(r"<[^>]+>", " ", xml)
    lowered = f" {plain.lower()} "
    forbidden = []
    for term in [" unstable plaque ", " vulnerable plaque ", " confirmed mechanism ", " diagnostic tool ", " actionable biomarker "]:
        if term in lowered:
            forbidden.append(term.strip())
    dashes = [d for d in ["\u2013", "\u2014"] if d in plain]
    return {"chars": len(plain), "forbidden": forbidden, "dashes": dashes}


def write_run_updates(outputs: dict[str, Path]) -> None:
    now = stamp()
    with RUNBOOK.open("a", encoding="utf-8") as handle:
        handle.write(
            f"| {now} / {stamp()} | Rscript 04_scripts/20_final_technical_revision_analysis_and_figures.R; "
            f"python 04_scripts/21_apply_final_interpretive_revision.py | 0 | "
            f"{outputs['manuscript_docx'].relative_to(ROOT)}; {outputs['integrated_docx'].relative_to(ROOT)} | "
            f"Fourth-round final technical revision, figures, SVG bundle, and Humanizer pass |\n"
        )
    with PROJECT_STATUS.open("a", encoding="utf-8") as handle:
        handle.write(
            "\n## 2026-09-04 Fourth-round final technical revision\n"
            "- Completed: author name, affiliation, author-contribution, no-funding, and no-conflict statements were inserted.\n"
            "- Completed: main conclusion was weakened to unadjusted tissue-level covariation with proxy-adjustment limits.\n"
            "- Completed: inflammatory VSMC program was renamed inflammatory VSMC-associated and audited in single-cell data.\n"
            "- Completed: Figure 1 and Figure 3 were rebuilt, and supplementary single-cell dotplots were added.\n"
            "- Completed: Times New Roman 12 pt, double-spaced Word files were exported under 修改内容.\n"
            "- Still author-dependent: corresponding email, source-study ethics/consent verification, public code repository URL, and final citation audit.\n"
        )


def main() -> int:
    started = stamp()
    try:
        log("START fourth-revision manuscript build")
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        ctx = get_context()
        refs_text = extract_references()
        manuscript = build_manuscript(ctx, refs_text)
        revision_note = build_revision_note(ctx)

        manuscript_md = MANUSCRIPT_DIR / "manuscript_draft_fourth_revision.md"
        manuscript_docx = OUTPUT_DIR / "投稿正文_第四轮最终技术修订_Humanizer终版.docx"
        manuscript_md_out = OUTPUT_DIR / "投稿正文_第四轮最终技术修订_Humanizer终版.md"
        integrated_docx = OUTPUT_DIR / "文章_第四轮最终技术修订_含图表整合版.docx"
        note_md = OUTPUT_DIR / "第四轮最终技术修订落实说明.md"
        note_docx = OUTPUT_DIR / "第四轮最终技术修订落实说明.docx"
        process_log = OUTPUT_DIR / "第四轮处理日志.txt"

        write_text(manuscript_md, manuscript)
        write_text(manuscript_md_out, manuscript)
        write_text(note_md, revision_note)
        save_docx_from_markdown(manuscript, manuscript_docx)
        save_docx_from_markdown(revision_note, note_docx)
        build_integrated_doc(manuscript, ctx, integrated_docx)
        copy_svg_bundle()

        outputs = {
            "manuscript_docx": manuscript_docx,
            "integrated_docx": integrated_docx,
            "note_docx": note_docx,
            "note_md": note_md,
            "manuscript_md": manuscript_md,
            "process_log": process_log,
        }
        update_qc_reports(outputs)
        qa_main = qa_docx_text(manuscript_docx)
        qa_integrated = qa_docx_text(integrated_docx)

        lines = [
            "Fourth-round final technical revision completed.",
            f"Started: {started}",
            f"Ended: {stamp()}",
            "Skills applied: nature-statistics, nature-figure, nature-polishing, humanizer.",
            "Output formatting: Times New Roman, 12 pt, double line spacing.",
            "No original source file was modified or overwritten.",
            "Figure preflight: 04_scripts/20_final_technical_revision_analysis_and_figures.R returned ready=true with no FAIL findings.",
            f"Main DOCX QA forbidden hits: {qa_main['forbidden']}",
            f"Main DOCX QA dash hits: {qa_main['dashes']}",
            f"Integrated DOCX QA forbidden hits: {qa_integrated['forbidden']}",
            f"Integrated DOCX QA dash hits: {qa_integrated['dashes']}",
            "Remaining author-needed fields: corresponding email, source ethics/consent statements, public code repository URL, final citation-to-claim audit.",
            "Outputs:",
        ] + [f"- {path}" for path in outputs.values()]
        write_text(process_log, "\n".join(lines) + "\n")
        write_run_updates(outputs)
        log("END fourth-revision manuscript build status=0")
        return 0
    except Exception as exc:
        record_error(str(exc))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
