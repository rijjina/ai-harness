# Make `teamai` and `node` findable for hooks that agents run through Git Bash (`bash -lc`),
# even when the agent app starts hooks with a reduced PATH. Safe to re-run.
$f = "$HOME\.bash_profile"
$dirs = @((Split-Path (Get-Command node).Source), (Split-Path (Get-Command teamai).Source)) | Select-Object -Unique | ForEach-Object { '/' + $_.Substring(0,1).ToLower() + ($_.Substring(2) -replace '\\','/') }
$line = 'export PATH="' + ($dirs -join ':') + ':$PATH"  # teamai hooks'
if (-not (Test-Path $f)) { Set-Content $f '[ -f ~/.bashrc ] && . ~/.bashrc' }
if (-not (Select-String -Path $f -SimpleMatch 'teamai hooks' -Quiet)) { Add-Content $f $line }
Get-Content $f
