<#
.SYNOPSIS
  Imprint the lazy-code rule into every coding agent's user-level config.

.DESCRIPTION
  Copies SKILL.md / RULE.md (same folder) into each host's global rule location.
  Idempotent: appended sections sit between lazy-code markers and are replaced on
  re-run. Standalone files are overwritten, with a .bak of anything replaced.

.EXAMPLE
  pwsh -File install.ps1                 # user-level hosts only
  pwsh -File install.ps1 -WhatIf         # show what would change
  pwsh -File install.ps1 -Repo D:\path   # also write that repo's AGENTS.md + copilot instructions
#>
[CmdletBinding(SupportsShouldProcess)]
param(
  [string]$Repo,
  [string]$Source = $PSScriptRoot
)

$ErrorActionPreference = 'Stop'
$rule  = Join-Path $Source 'RULE.md'
# SKILL.md is the canonical skill one level up; fall back to alongside RULE.md
$skill = Join-Path (Split-Path $Source) 'SKILL.md'
if (-not (Test-Path $skill)) { $skill = Join-Path $Source 'SKILL.md' }
foreach ($f in $skill, $rule) {
  if (-not (Test-Path $f)) { throw "missing $f" }
}
$body  = Get-Content $rule -Raw
$home_ = [Environment]::GetFolderPath('UserProfile')
$start = '<!-- lazy-code:start -->'
$end   = '<!-- lazy-code:end -->'
$written = @()

function Write-Whole([string]$Path, [string]$Text) {
  if (Test-Path $Path) {
    if ((Get-Content $Path -Raw) -eq $Text) { $script:written += "unchanged  $Path"; return }
    Copy-Item $Path "$Path.bak" -Force
  }
  if ($PSCmdlet.ShouldProcess($Path, 'write')) {
    New-Item (Split-Path $Path) -ItemType Directory -Force | Out-Null
    Set-Content $Path $Text -Encoding UTF8 -NoNewline
  }
  $script:written += "wrote      $Path"
}

function Write-Section([string]$Path, [string]$Text) {
  $block = "$start`n$Text`n$end`n"
  $existing = if (Test-Path $Path) { Get-Content $Path -Raw } else { '' }
  # regex-free splice: markers are literal, so index them directly
  $i = $existing.IndexOf($start)
  $j = $existing.IndexOf($end)
  $new = if ($i -ge 0 -and $j -gt $i) {
    $existing.Substring(0, $i) + $block + $existing.Substring($j + $end.Length).TrimStart("`r","`n")
  } else {
    ($existing.TrimEnd() + "`n`n" + $block).TrimStart("`r","`n")
  }
  if ($new -eq $existing) { $script:written += "unchanged  $Path"; return }
  if (Test-Path $Path) { Copy-Item $Path "$Path.bak" -Force }
  if ($PSCmdlet.ShouldProcess($Path, 'splice')) {
    New-Item (Split-Path $Path) -ItemType Directory -Force | Out-Null
    Set-Content $Path $new -Encoding UTF8 -NoNewline
  }
  $script:written += "spliced    $Path"
}

# --- Claude Code: a real skill, not an instruction blob -----------------------
Write-Whole (Join-Path $home_ '.claude\skills\lazy-code\SKILL.md') (Get-Content $skill -Raw)

# --- AGENTS.md convention (Codex, OpenCode, and most agents that read it) -----
Write-Section (Join-Path $home_ '.codex\AGENTS.md') $body
Write-Section (Join-Path $home_ '.config\opencode\AGENTS.md') $body

# --- Gemini CLI ---------------------------------------------------------------
Write-Section (Join-Path $home_ '.gemini\GEMINI.md') $body

# --- Cursor: global rule file needs its own frontmatter ------------------------
$mdc = "---`ndescription: Write the least code that actually works.`nalwaysApply: true`n---`n`n$body"
Write-Whole (Join-Path $home_ '.cursor\rules\lazy-code.mdc') $mdc

# --- Windsurf, Cline, Kiro -----------------------------------------------------
Write-Section (Join-Path $home_ '.codeium\windsurf\memories\global_rules.md') $body
Write-Whole  (Join-Path $home_ 'Documents\Cline\Rules\lazy-code.md') $body
Write-Whole  (Join-Path $home_ '.kiro\steering\lazy-code.md') $body

# --- Per-repo targets (Copilot has no user-level instructions file) ------------
if ($Repo) {
  if (-not (Test-Path $Repo)) { throw "no such repo: $Repo" }
  Write-Section (Join-Path $Repo 'AGENTS.md') $body
  Write-Section (Join-Path $Repo '.github\copilot-instructions.md') $body
}

$written | Sort-Object | ForEach-Object { Write-Host $_ }
Write-Host ""
Write-Host "$($written.Count) targets. Re-run any time; sections between the lazy-code markers are replaced, not duplicated."
if (-not $Repo) { Write-Host "Copilot is per-repo only: re-run with -Repo <path> for each repo that needs it." }
