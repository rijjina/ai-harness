# One runnable check for install.ps1's splice logic. Run: pwsh -File selftest.ps1
$ErrorActionPreference = 'Stop'
$repo = Join-Path ([IO.Path]::GetTempPath()) ("lazycode-" + [guid]::NewGuid())
New-Item $repo -ItemType Directory -Force | Out-Null
try {
  $agents = Join-Path $repo 'AGENTS.md'
  Set-Content $agents "# repo rules`n`nrun tests`n" -Encoding UTF8

  & (Join-Path $PSScriptRoot 'install.ps1') -Repo $repo | Out-Null
  & (Join-Path $PSScriptRoot 'install.ps1') -Repo $repo | Out-Null   # twice: must not duplicate

  $t = Get-Content $agents -Raw
  $starts = ([regex]::Matches($t, [regex]::Escape('<!-- lazy-code:start -->'))).Count
  if ($starts -ne 1)            { throw "splice duplicated: $starts markers" }
  if ($t -notmatch 'run tests') { throw 'splice ate the existing content' }
  if ($t -notmatch 'The ladder'){ throw 'rule body missing' }
  'ok: spliced once, existing content preserved'
} finally {
  Remove-Item $repo -Recurse -Force -ErrorAction SilentlyContinue
}
