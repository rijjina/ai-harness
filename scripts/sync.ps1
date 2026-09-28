# Commit + push harness edits (from Obsidian or anywhere), pull teammates' changes,
# refresh the Codex/Antigravity rules blocks, then let teamai deliver to agents.
param([string]$Message = "harness: update $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
$ErrorActionPreference = 'Stop'
$Harness = Split-Path -Parent $PSScriptRoot
Push-Location $Harness
try {
  git add -A
  git diff --cached --quiet
  if ($LASTEXITCODE -ne 0) { git commit -m $Message | Out-Host }
  git pull --rebase --autostash | Out-Host
  git push | Out-Host
} finally { Pop-Location }
& (Join-Path $PSScriptRoot 'rules-block.ps1') -Harness $Harness
teamai pull
