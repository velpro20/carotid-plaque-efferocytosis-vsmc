param([string]$Root)
$ErrorActionPreference = "Stop"
$md = Join-Path $Root "06_manuscript\manuscript_draft.md"
$docx = Join-Path $Root "06_manuscript\manuscript_draft.docx"
$pdf = Join-Path $Root "06_manuscript\manuscript_draft.pdf"
$title = Join-Path $Root "06_manuscript\title_page.docx"
$legends = Join-Path $Root "06_manuscript\figure_legends.docx"
$tables = Join-Path $Root "06_manuscript\tables.docx"
$supp = Join-Path $Root "06_manuscript\supplementary_materials.docx"
function New-WordDoc([string]$TextPath, [string]$DocPath, [string]$PdfPath) {
  $word = New-Object -ComObject Word.Application
  $word.Visible = $false
  $doc = $word.Documents.Add()
  $text = [System.IO.File]::ReadAllText((Resolve-Path $TextPath), [System.Text.Encoding]::UTF8)
  $doc.Content.Text = $text
  $doc.SaveAs([ref]$DocPath, [ref]16)
  if ($PdfPath) { $doc.ExportAsFixedFormat($PdfPath, 17) }
  $doc.Close()
  $word.Quit()
  [System.Runtime.InteropServices.Marshal]::ReleaseComObject($doc) | Out-Null
  [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
}
New-WordDoc $md $docx $pdf
New-WordDoc $md $title $null
New-WordDoc (Join-Path $Root "06_manuscript\figure_legends.txt") $legends $null
New-WordDoc (Join-Path $Root "06_manuscript\tables.txt") $tables $null
New-WordDoc (Join-Path $Root "06_manuscript\supplementary_materials.txt") $supp $null
Write-Output "Word exports completed"

