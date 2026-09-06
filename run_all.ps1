param([switch]$ContinueOnError = $true)
$ErrorActionPreference = "Continue"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $Root
$log = Join-Path $Root "08_logs\run_all.log"
$runbook = Join-Path $Root "RUNBOOK.md"
$scripts = @(
  "00_preflight.R",
  "01_download_and_audit.R",
  "02_bulk_qc_and_preprocess.R",
  "03_bulk_differential_expression.R",
  "04_signature_and_enrichment.R",
  "05_network_analysis_optional.R",
  "06_scrna_qc_annotation.R",
  "07_scrna_macrophage_vsmc.R",
  "08_cell_communication_optional.R",
  "09_spatial_validation_optional.R",
  "10_external_validation.R",
  "11_figure_generation.R",
  "12_manuscript_generation.R",
  "13_reference_audit.R"
)
foreach($script in $scripts) {
  $start = Get-Date
  Add-Content -LiteralPath $log -Value ("[$($start.ToString('s'))] START $script")
  & Rscript (Join-Path $Root "04_scripts\$script") *> (Join-Path $Root "08_logs\$($script -replace '\.R$','').log")
  $code = $LASTEXITCODE
  $end = Get-Date
  Add-Content -LiteralPath $log -Value ("[$($end.ToString('s'))] END $script status=$code duration_sec=$([int]($end-$start).TotalSeconds)")
  Add-Content -LiteralPath $runbook -Value ("| $($start.ToString('s')) / $($end.ToString('s')) | Rscript 04_scripts/$script | $code | See 08_logs/$($script -replace '\.R$','').log | Automatically recorded |")
  if($code -ne 0) {
    Add-Content -LiteralPath (Join-Path $Root "08_logs\error_log.md") -Value ("`n- $($end.ToString('s')) | $script returned status $code; output preserved. The controller continued.")
    if(-not $ContinueOnError) { break }
  }
}
Add-Content -LiteralPath $log -Value ("[$((Get-Date).ToString('s'))] run_all completed")

# The manuscript-generation R script creates the baseline evidence-bounded draft.
# The skill-based revision then replaces scaffold wording, cleans references,
# regenerates support files, and rebuilds the integrated author-review document.
$py = "C:\Users\velpro\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
$revisionStart = Get-Date
& $py (Join-Path $Root "04_scripts\15_skill_based_revision.py") *> (Join-Path $Root "08_logs\15_skill_based_revision.log")
$revisionCode = $LASTEXITCODE
$revisionEnd = Get-Date
Add-Content -LiteralPath $runbook -Value ("| $($revisionStart.ToString('s')) / $($revisionEnd.ToString('s')) | python 04_scripts/15_skill_based_revision.py | $revisionCode | See 08_logs/15_skill_based_revision.log | Skill-based manuscript revision and reference cleanup |")
if($revisionCode -ne 0) {
  Add-Content -LiteralPath (Join-Path $Root "08_logs\error_log.md") -Value ("`n- $($revisionEnd.ToString('s')) | 15_skill_based_revision.py returned status $revisionCode; baseline manuscript retained.")
}

$integratedStart = Get-Date
& $py (Join-Path $Root "04_scripts\14_integrated_review_doc.py") *> (Join-Path $Root "08_logs\14_integrated_review_doc.log")
$integratedCode = $LASTEXITCODE
$integratedEnd = Get-Date
Add-Content -LiteralPath $runbook -Value ("| $($integratedStart.ToString('s')) / $($integratedEnd.ToString('s')) | python 04_scripts/14_integrated_review_doc.py | $integratedCode | See 08_logs/14_integrated_review_doc.log | Rebuilt integrated author-review Word document |")
if($integratedCode -ne 0) {
  Add-Content -LiteralPath (Join-Path $Root "08_logs\error_log.md") -Value ("`n- $($integratedEnd.ToString('s')) | 14_integrated_review_doc.py returned status $integratedCode; prior integrated document retained.")
}

$pdfStart = Get-Date
& (Join-Path $Root "04_scripts\16_export_revised_pdf.ps1") -Root $Root *> (Join-Path $Root "08_logs\16_export_revised_pdf_controller.log")
$pdfCode = $LASTEXITCODE
$pdfEnd = Get-Date
Add-Content -LiteralPath $runbook -Value ("| $($pdfStart.ToString('s')) / $($pdfEnd.ToString('s')) | PowerShell 04_scripts/16_export_revised_pdf.ps1 | $pdfCode | See 08_logs/16_export_revised_pdf_controller.log | Exported revised manuscript PDF |")
if($pdfCode -ne 0) {
  Add-Content -LiteralPath (Join-Path $Root "08_logs\error_log.md") -Value ("`n- $($pdfEnd.ToString('s')) | 16_export_revised_pdf.ps1 returned status $pdfCode; revised DOCX retained.")
}

$qcStart = Get-Date
& $py (Join-Path $Root "04_scripts\17_final_qc.py") *> (Join-Path $Root "08_logs\17_final_qc.log")
$qcCode = $LASTEXITCODE
$qcEnd = Get-Date
Add-Content -LiteralPath $runbook -Value ("| $($qcStart.ToString('s')) / $($qcEnd.ToString('s')) | python 04_scripts/17_final_qc.py | $qcCode | See 08_logs/17_final_qc.log | Generated final QC/readiness/delivery reports |")
if($qcCode -ne 0) {
  Add-Content -LiteralPath (Join-Path $Root "08_logs\error_log.md") -Value ("`n- $($qcEnd.ToString('s')) | 17_final_qc.py returned status $qcCode; QC reports may be stale.")
}

Add-Content -LiteralPath $log -Value ("[$((Get-Date).ToString('s'))] post-processing completed revision=$revisionCode integrated=$integratedCode pdf=$pdfCode qc=$qcCode")
