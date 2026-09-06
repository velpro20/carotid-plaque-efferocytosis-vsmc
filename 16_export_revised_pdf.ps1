param([string]$Root)
$ErrorActionPreference = "Stop"
if(-not $Root) { $Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path }
$docx = Join-Path $Root "06_manuscript\manuscript_draft.docx"
$pdf = Join-Path $Root "06_manuscript\manuscript_draft.pdf"
$log = Join-Path $Root "08_logs\16_export_revised_pdf.log"
$start = Get-Date
$word = $null
$doc = $null
try {
  if(-not (Test-Path -LiteralPath $docx)) { throw "Missing revised manuscript DOCX: $docx" }
  $word = New-Object -ComObject Word.Application
  $word.Visible = $false
  $doc = $word.Documents.Open($docx, $false, $true)
  $doc.ExportAsFixedFormat($pdf, 17)
  $end = Get-Date
  Add-Content -LiteralPath $log -Value "[$($start.ToString('s'))] START revised PDF export"
  Add-Content -LiteralPath $log -Value "[$($end.ToString('s'))] END revised PDF export status=0 output=$pdf"
  Add-Content -LiteralPath (Join-Path $Root "RUNBOOK.md") -Value "| $($start.ToString('s')) / $($end.ToString('s')) | PowerShell 04_scripts/16_export_revised_pdf.ps1 | 0 | 06_manuscript/manuscript_draft.pdf; 08_logs/16_export_revised_pdf.log | Exported revised manuscript PDF from revised DOCX |"
}
catch {
  $end = Get-Date
  Add-Content -LiteralPath $log -Value "[$($end.ToString('s'))] END revised PDF export status=1 error=$($_.Exception.Message)"
  Add-Content -LiteralPath (Join-Path $Root "08_logs\error_log.md") -Value "`n- $($end.ToString('s')) | 16_export_revised_pdf.ps1 | $($_.Exception.Message)"
  Add-Content -LiteralPath (Join-Path $Root "RUNBOOK.md") -Value "| $($start.ToString('s')) / $($end.ToString('s')) | PowerShell 04_scripts/16_export_revised_pdf.ps1 | 1 | 08_logs/16_export_revised_pdf.log | Revised PDF export failed; DOCX retained |"
  exit 1
}
finally {
  if($doc) { $doc.Close($false); [System.Runtime.InteropServices.Marshal]::ReleaseComObject($doc) | Out-Null }
  if($word) { $word.Quit(); [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null }
}
