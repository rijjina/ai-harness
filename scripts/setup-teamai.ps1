<#
One-time setup on Windows (safe to re-run; finished steps are skipped):
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
# Native tools write progress to stderr; failures are caught by Run/throw instead.
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Harness = Split-Path -Parent $PSScriptRoot
function Step($m) { Write-Host "`n==> $m" -ForegroundColor Cyan }
# Run a native command; stop the whole script if it fails.
function Run([string]$what, [scriptblock]$cmd) {
  $global:LASTEXITCODE = 0
  & $cmd
  if ($LASTEXITCODE -ne 0) { throw "FAILED ($LASTEXITCODE): $what" }
}

Step 'Checking prerequisites'
foreach ($c in 'git', 'node', 'npm') {
  if (-not (Get-Command $c -ErrorAction SilentlyContinue)) { throw "$c not found on PATH - install it first." }
}
$gitBash = Join-Path $env:ProgramFiles 'Git\bin\bash.exe'
if (-not (Test-Path $gitBash)) { Write-Warning "Git Bash not found at $gitBash - teamai hooks need Git for Windows." }
if ($env:NODE_OPTIONS) { Write-Warning "NODE_OPTIONS is set: '$env:NODE_OPTIONS' (a large --max-old-space-size can make Node fail with 'VirtualAlloc failed')." }
$os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
$freeRamGB = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
$freeCommitGB = [math]::Round($os.FreeVirtualMemory / 1MB, 1)
Write-Host "Free RAM: $freeRamGB GB   Free commit (RAM + page file): $freeCommitGB GB"
if ($freeCommitGB -lt 2) { throw "Windows is out of memory (free commit $freeCommitGB GB). Close apps or restart, then re-run." }
Run 'node smoke test' { node -e "process.exit(0)" }
$nodeMajor = [int]((node -v).TrimStart('v').Split('.')[0])
if ($nodeMajor -lt 20) { throw "Node 20+ required (found $(node -v))." }

Step "Pushing $Harness to $RepoUrl"
Push-Location $Harness
try {
  $safe = @(git config --global --get-all safe.directory)
  $h = $Harness -replace '\\', '/'
  if ($safe -notcontains $h) { git config --global --add safe.directory $h }
  if (-not (Test-Path '.git')) { Run 'git init' { git init -b main } }
  git add -A
  git diff --cached --quiet
  if ($LASTEXITCODE -ne 0) { Run 'git commit' { git commit -m 'Initial harness: skills, rules, docs' } }
  if (-not (git remote)) { Run 'git remote add' { git remote add origin $RepoUrl } }
  Run 'git branch -M main' { git branch -M main }
  git ls-remote --exit-code --heads origin main | Out-Null
  if ($LASTEXITCODE -eq 0) { Run 'git pull --rebase (merge commits teamai made on GitHub)' { git pull --rebase --autostash origin main } }
  Run "git push (sign in to GitHub if a window opens)" { git push -u origin main }
} finally { Pop-Location }

Step "Installing teamai-cli@$TeamaiVersion"
$have = (npm ls -g teamai-cli --depth=0 | Select-String "teamai-cli@$TeamaiVersion")
if ($have) { Write-Host "already installed" } else { Run 'npm install' { npm install -g "teamai-cli@$TeamaiVersion" } }

Step 'teamai init (user scope, Claude Code + Codex)'
foreach ($d in '.claude', '.codex') { New-Item -ItemType Directory -Force (Join-Path $HOME $d) -ErrorAction Stop | Out-Null }
if (Test-Path (Join-Path $HOME '.teamai\config.yaml')) { Write-Host "already initialized" }
else { Run 'teamai init' { teamai init $RepoUrl --scope user --agent claude,codex --force } }
Run 'teamai pull' { teamai pull }
Push-Location $Harness; Run 'git pull' { git pull --rebase }; Pop-Location   # get teamai.yaml etc. created by init

Step "Linking harness into Obsidian vault"
$link = Join-Path $Vault 'TeamAI'
if (Test-Path $link) { Write-Host "exists, leaving as is: $link" }
else { New-Item -ItemType Junction -Path $link -Target $Harness -ErrorAction Stop | Out-Null; Write-Host "junction: $link -> $Harness" }

if (-not $SkipAntigravity) {
  Step 'Antigravity: skills link'
  $agSkills = Join-Path $HOME '.gemini\antigravity\skills'
  if (Test-Path $agSkills) { Write-Host "exists, leaving as is: $agSkills" }
  else {
    New-Item -ItemType Directory -Force (Split-Path -Parent $agSkills) -ErrorAction Stop | Out-Null
    New-Item -ItemType Junction -Path $agSkills -Target (Join-Path $Harness 'skills') -ErrorAction Stop | Out-Null
    Write-Host "junction: $agSkills -> $Harness\skills  (verify Antigravity lists the skills)"
  }
}

Step 'Rules blocks for Codex / Antigravity'
& (Join-Path $PSScriptRoot 'rules-block.ps1') -Harness $Harness

Step 'teamai doctor'
teamai doctor
Write-Host "`nDone. Edit in Obsidian under TeamAI\, then run scripts\sync.ps1." -ForegroundColor Green
