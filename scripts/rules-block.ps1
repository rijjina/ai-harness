# Writes harness rules into agents that teamai cannot reach natively:
#   Codex       -> ~/.codex/AGENTS.md   (Codex reads AGENTS.md, not .codex/rules/*.md)
#   (Antigravity gets rules + skills from the harness itself as a plugin: plugin.json + ~/.gemini/config/plugins.json)
# Content between the markers is replaced on every run; the rest of each file is kept.
param([string]$Harness = (Split-Path -Parent $PSScriptRoot))

$start = '<!-- [harness:rules:start] -->'
$end   = '<!-- [harness:rules:end] -->'
$rules = Get-ChildItem -Path (Join-Path $Harness 'rules') -Filter *.md | Sort-Object Name |
         ForEach-Object { (Get-Content $_.FullName -Raw -Encoding UTF8).Trim() }
$block = "$start`r`n<!-- generated from $Harness\rules - edit there, not here -->`r`n`r`n" + ($rules -join "`r`n`r`n") + "`r`n$end"

$targets = @(
  (Join-Path $HOME '.codex\AGENTS.md')
)
foreach ($t in $targets) {
  $dir = Split-Path -Parent $t
  if (-not (Test-Path $dir)) { Write-Host "skip (agent not installed): $t"; continue }
  $old = if (Test-Path $t) { Get-Content $t -Raw -Encoding UTF8 } else { '' }
  if ($null -eq $old) { $old = '' }
  $pattern = [regex]::Escape($start) + '[\s\S]*?' + [regex]::Escape($end)
  if ($old -match $pattern) { $new = [regex]::Replace($old, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $block }) }
  else { $new = ($old.TrimEnd() + "`r`n`r`n" + $block + "`r`n").TrimStart() }
  if ($new -ne $old) {
    if (Test-Path $t) { Copy-Item $t "$t.bak" -Force }
    [IO.File]::WriteAllText($t, $new, (New-Object System.Text.UTF8Encoding $false))
    Write-Host "updated rules block: $t"
  } else { Write-Host "up to date: $t" }
}
