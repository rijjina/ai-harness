<#
One-time setup on Windows:
  1. push D:\AI\harness to your GitHub repo
  2. install teamai-cli and init it (user scope) for Claude Code + Codex
  3. junction the harness into the Obsidian vault as <vault>\TeamAI
  4. link skills for Antigravity and write the rules blocks
Usage:
  powershell -ExecutionPolicy Bypass -File D:\AI\harness\scripts\setup-teamai.ps1 -RepoUrl https://github.com/rijjina/ai-harness.git
#>
param(
  [Parameter(Mandatory = $true)][string]$RepoUrl,
  [string]$Vault = 'D:\OneDrive\note',
  [string]$TeamaiVersion = '0.25.0',
  [switch]$SkipAntigravity
)
$ErrorActionPreference = 'Stop'
$Harness = Split-Path -Parent $PSScriptRoot
function Step($m) { Write-Host "`n==> $m" -ForegroundColor Cyan }

Step 'Checking prerequisites'
foreach ($c in 'git', 'node', 'npm') {
  if (-not (Get-Command $c -ErrorAction SilentlyContinue)) { throw "$c not found on PATH - install it first." }
}
$gitBash = Join-Path $env:ProgramFiles 'Git\bin\bash.exe'
if (-not (Test-Path $gitBash)) { Write-Warning "Git Bash not found at $gitBash - teamai hooks need Git for Windows." }
$nodeMajor = [int]((node -v).TrimStart('v').Split('.')[0])
if ($nodeMajor -lt 20) { throw "Node 20+ required (found $(node -v))." }

Step "Pushing $Harness to $RepoUrl"
Push-Location $Harness
try {
  if (-not (Test-Path '.git')) { git init -b main | Out-Host }
  git config --global --add safe.directory ($Harness -replace '\\', '/') 2>$null
  git add -A
  git diff --cached --quiet
  if ($LASTEXITCODE -ne 0) { git commit -m 'Initial harness: skills, rules, docs' | Out-Host }
  if (-not (git remote)) { git remote add origin $RepoUrl }
  git push -u origin main | Out-Host
} finally { Pop-Location }

Step "Installing teamai-cli@$TeamaiVersion"
npm install -g "teamai-cli@$TeamaiVersion" | Out-Host

Step 'teamai init (user scope, Claude Code + Codex)'
foreach ($d in '.claude', '.codex') { New-Item -ItemType Directory -Force (Join-Path $HOME $d) | Out-Null }
teamai init $RepoUrl --scope user --agent claude,codex
teamai pull
Push-Location $Harness; git pull --rebase | Out-Host; Pop-Location   # get teamai.yaml etc. created by init

Step "Linking harness into Obsidian vault"
$link = Join-Path $Vault 'TeamAI'
if (Test-Path $link) { Write-Host "exists, leaving as is: $link" }
else { New-Item -ItemType Junction -Path $link -Target $Harness | Out-Null; Write-Host "junction: $link -> $Harness" }

if (-not $SkipAntigravity) {
  Step 'Antigravity: skills link'
  $agSkills = Join-Path $HOME '.gemini\antigravity\skills'
  if (Test-Path $agSkills) { Write-Host "exists, leaving as is: $agSkills" }
  else {
    New-Item -ItemType Directory -Force (Split-Path -Parent $agSkills) | Out-Null
    New-Item -ItemType Junction -Path $agSkills -Target (Join-Path $Harness 'skills') | Out-Null
    Write-Host "junction: $agSkills -> $Harness\skills  (verify Antigravity lists the skills)"
  }
}

Step 'Rules blocks for Codex / Antigravity'
& (Join-Path $PSScriptRoot 'rules-block.ps1') -Harness $Harness

Step 'teamai doctor'
teamai doctor
Write-Host "`nDone. Edit in Obsidian under TeamAI\, then run scripts\sync.ps1." -ForegroundColor Green
