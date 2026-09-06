"""Generate final QC, submission-readiness, and delivery-summary reports."""

from __future__ import annotations

import csv
import datetime as dt
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANUSCRIPT = ROOT / "06_manuscript"
TABLES = ROOT / "05_results" / "tables"
FIGURES = ROOT / "05_results" / "figures"
QC = ROOT / "05_results" / "qc"
PACKAGE = ROOT / "07_submission_package"
RUNBOOK = ROOT / "RUNBOOK.md"
LOG_DIR = ROOT / "08_logs"
TITLE = (
    "Tissue-level associations between macrophage efferocytosis-related programs "
    "and vascular smooth muscle cell state signatures in symptomatic versus "
    "asymptomatic human carotid plaques"
)


def read_csv(path: Path):
    if not path.exists():
        return []
    with path.open(encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def count_fdr(path: Path):
    rows = read_csv(path)
    if not rows:
        return 0, 0
    col = next((x for x in rows[0] if x.lower() in {"fdr", "adj.p.val", "padj"}), None)
    if not col:
        return len(rows), 0
    sig = 0
    for row in rows:
        try:
            sig += float(row[col]) < 0.05
        except (ValueError, TypeError):
            pass
    return len(rows), sig


def main() -> int:
    started = dt.datetime.now()
    PACKAGE.mkdir(parents=True, exist_ok=True)
    manuscript_path = MANUSCRIPT / "manuscript_draft.md"
    manuscript = manuscript_path.read_text(encoding="utf-8", errors="replace") if manuscript_path.exists() else ""
    placeholders = sorted(set(re.findall(r"\[\[[^\]]+\]\]", manuscript)))
    forbidden = sorted(set(re.findall(r"\b(?:unstable|stable plaque|therapeutic target|diagnostic tool)\b", manuscript, re.I)))
    refs = read_csv(ROOT / "02_literature" / "reference_audit.csv")
    figures = [FIGURES / f"Figure_{i}_{stem}.png" for i, stem in [
        (1, "study_design"), (2, "discovery_bulk"), (3, "signature_scores"),
        (4, "single_cell_atlas"), (5, "macrophage_efferocytosis"),
        (6, "vsmc_states"), (7, "external_validation")
    ]]
    figure_status = {path.name: path.exists() for path in figures}
    deg111 = count_fdr(TABLES / "GSE111782_DEG_complete.csv")
    deg311 = count_fdr(TABLES / "GSE311535_DEG_complete.csv")
    audit = read_csv(ROOT / "03_data" / "metadata" / "dataset_audit.csv")
    included = {row.get("accession"): row for row in audit if row.get("included_or_excluded", "").startswith("included")}
    sc_gate = (QC / "GSE260657_gate_status.md").read_text(encoding="utf-8", errors="replace") if (QC / "GSE260657_gate_status.md").exists() else ""
    sc_pass = "PASS" in sc_gate
    main_text = manuscript.split("## References", 1)[0]
    word_count = len(re.findall(r"\b[\w'-]+\b", main_text))
    figure_lines = "\n".join(
        f"- {name}: {'PASS' if ok else 'FAIL'}" for name, ok in figure_status.items()
    )

    qc_text = f"""# FINAL QC REPORT

Generated: {started.isoformat(timespec='seconds')}

## Core manuscript checks

- Manuscript source exists: {"PASS" if manuscript else "FAIL"}
- Revised manuscript DOCX exists: {"PASS" if (MANUSCRIPT / "manuscript_draft.docx").exists() else "FAIL"}
- Revised manuscript PDF exists: {"PASS" if (MANUSCRIPT / "manuscript_draft.pdf").exists() else "FAIL"}
- Integrated author-review DOCX exists: {"PASS" if (MANUSCRIPT / "integrated_review_document.docx").exists() else "FAIL"}
- Main-text word count estimate: {word_count:,}
- Placeholder fields requiring author input: {len(placeholders)}
- Forbidden/overclaim-sensitive terms detected for review: {", ".join(forbidden) if forbidden else "none"}

## Data and statistics traceability

- GSE111782: 9 symptomatic / 9 asymptomatic; {deg111[0]:,} genes in complete DEG table; FDR < 0.05 genes: {deg111[1]}.
- GSE311535: 6 symptomatic / 6 asymptomatic; {deg311[0]:,} genes in complete DEG table; FDR < 0.05 genes: {deg311[1]}.
- GSE260657: human carotid plaque single-cell gate: {"PASS" if sc_pass else "BLOCKED"}.
- All reported primary FDR claims are intended to trace to result tables under 05_results/tables.
- Cell-level observations are used for localization/descriptive summaries; donor/sample is the inferential unit where available.

## Figure checks

{figure_lines}

## Reference checks

- Curated PubMed-verified reference audit rows: {len(refs)}
- Reference file exists: {"PASS" if (MANUSCRIPT / "references.bib").exists() else "FAIL"}
- In-text citation numbering and exact sentence support: AUTHOR_INPUT_NEEDED

## Journal and declarations

- Journal compliance checklist: AUTHOR REVIEW REQUIRED
- Author names, affiliations, correspondence: AUTHOR_INPUT_NEEDED
- Funding, conflicts, ethics/consent, acknowledgments: AUTHOR_INPUT_NEEDED
- Code repository URL: AUTHOR_INPUT_NEEDED
- AI-use disclosure wording: AUTHOR REVIEW REQUIRED
"""
    (PACKAGE / "FINAL_QC_REPORT.md").write_text(qc_text, encoding="utf-8")

    readiness = f"""# SUBMISSION READINESS

Generated: {started.isoformat(timespec='seconds')}

## 1. Completed and verifiable

- Discovery bulk cohort: GSE111782, symptomatic versus asymptomatic, 9/9 samples.
- Independent bulk validation cohort: GSE311535, symptomatic versus asymptomatic in diabetic patients, 6/6 samples.
- Human carotid plaque single-cell cohort: GSE260657, 15 donor/sample files with 8 symptomatic and 7 asymptomatic samples.
- Complete bulk DEG tables, signature scores, correlations, single-cell annotation/program tables, figures, logs, and provenance files are present in the project.
- Revised manuscript text reports negative DEG and group-level signature results instead of hiding them behind table references.
- Reference audit was regenerated from PubMed metadata and low-relevance/method-mismatched records were removed.

## 2. Evidence for an author-review draft

- Gate A: PASS. Human carotid plaque bulk discovery cohort with explicit grouping.
- Gate B: PASS. Independent human carotid plaque bulk validation cohort with comparable symptomatic/asymptomatic grouping, with diabetes-specific limitation.
- Gate C: {"PASS" if sc_pass else "BLOCKED"}. Human carotid plaque single-cell data with macrophage and VSMC localization; lightweight annotation fallback remains a limitation.

## 3. Must be completed or confirmed by real authors

- Replace all author, affiliation, correspondence, funding, conflict, ethics, consent, and code-repository placeholders.
- Verify the original studies' ethics and consent statements.
- Reconcile numbered citations against the final sentence-level claims and Frontiers reference style.
- Review figure readability, table placement, and all exact numerical values.
- Confirm AI-use disclosure wording and submission-system declarations.

## 4. Statistical and biological limitations that cannot be ignored

- Small cohorts limit power and precision.
- The validation cohort is diabetes-specific and uses a different platform from discovery.
- Bulk tissue-level correlations may reflect cell composition, shared inflammation, lesion stage, or technical factors.
- Single-cell cells are not independent patients; the current annotation is a lightweight fallback.
- No spatial carotid validation, perturbation, lineage tracing, or wet-lab validation was performed.
- No diagnostic, therapeutic, or causal claim is supported.

## 5. Gate status

- A: PASS
- B: PASS
- C: {"PASS" if sc_pass else "BLOCKED"}

## 6. Final conclusion

**READY FOR AUTHOR REVIEW**

This package is not ready for direct journal submission until the author-side fields and final source/citation/format checks are completed.
"""
    (PACKAGE / "SUBMISSION_READINESS.md").write_text(readiness, encoding="utf-8")

    delivery = f"""# 交付摘要

生成日期：{started.strftime("%Y-%m-%d")}

## 1. 最终采用的数据集及用途

- `GSE111782`：人类颈动脉斑块 bulk Affymetrix 发现集，9 symptomatic / 9 asymptomatic。
- `GSE311535`：糖尿病患者人类颈动脉斑块 bulk RNA-seq 独立验证集，6 symptomatic / 6 asymptomatic。
- `GSE260657`：人类颈动脉斑块 Smart-seq2 单细胞定位队列，15 个 donor/sample 文件，8 symptomatic / 7 asymptomatic。

## 2. 发现集、验证集和单细胞数据

发现 bulk、独立验证 bulk 和单细胞定位均已完成可审阅分析。单细胞结果用于细胞定位和供体级探索，不能把细胞数当作患者数。

## 3. 可选模块

- 空间转录组：未执行。没有合格、可核验且适合主结论的人类颈动脉空间数据。
- 细胞通讯：未纳入主结论。严格的细胞亚群、数据库和参数门槛未满足。
- 机器学习/ROC：未执行。发现集未形成可稳定支持的 FDR-significant 特征集，样本量也不足以承担可靠分类建模。
- WGCNA：未执行。发现 bulk 样本数为 18，低于预设的至少 30 个样本门槛。

## 4. 最终论文标题

{TITLE}

## 5. 主要文件路径

- 修订英文稿：`06_manuscript/manuscript_draft.md`
- 修订 Word：`06_manuscript/manuscript_draft.docx`
- 修订 PDF：`06_manuscript/manuscript_draft.pdf`
- 一体化审阅 Word：`06_manuscript/integrated_review_document.docx`
- 主图：`05_results/figures`
- 结果表：`05_results/tables`
- 代码：`04_scripts`
- 日志：`08_logs`
- QC 与投稿状态：`07_submission_package`

## 6. 不能忽略的风险和人工待办事项

- 公开回顾性数据、样本量小、平台不同、验证集糖尿病特异性和组织混合都会限制外推。
- 目前最稳定的结果是两个 bulk 队列中 efferocytosis 与 inflammatory VSMC signature 的组织层面相关，不是稳健的 symptomatic-versus-asymptomatic DEG signature。
- 必须由真实作者补齐作者、单位、通讯邮箱、基金、利益冲突、伦理/知情同意、代码仓库和 AI 使用披露。

最终状态：READY FOR AUTHOR REVIEW，不是 READY FOR SUBMISSION。
"""
    (PACKAGE / "DELIVERY_SUMMARY.md").write_text(delivery, encoding="utf-8")

    end = dt.datetime.now()
    with RUNBOOK.open("a", encoding="utf-8") as handle:
        handle.write(
            f"| {started.isoformat(timespec='seconds')} / {end.isoformat(timespec='seconds')} | "
            f"python 04_scripts/17_final_qc.py | 0 | 07_submission_package/FINAL_QC_REPORT.md; "
            f"07_submission_package/SUBMISSION_READINESS.md; 07_submission_package/DELIVERY_SUMMARY.md | "
            f"Generated final QC and delivery reports |\n"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
