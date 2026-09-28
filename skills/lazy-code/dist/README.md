# lazy-code / dist

Host-native distribution of `../SKILL.md`. One canonical body, copied into each
agent's config location — no per-host forks to keep in sync.

- `RULE.md` — the skill body without frontmatter, for hosts that want plain markdown.
- `install.ps1` — writes it everywhere. Idempotent.
- `selftest.ps1` — the one runnable check: splices twice into a temp repo and
  asserts one marker pair and no lost content.

## Run

```powershell
pwsh -File install.ps1 -WhatIf      # see what would change
pwsh -File install.ps1              # user-level hosts
pwsh -File install.ps1 -Repo D:\AI\projects\active\forex-quant   # + that repo
```

## Targets

| Host | Path | Mode |
|---|---|---|
| Claude Code | `~/.claude/skills/lazy-code/SKILL.md` | whole file |
| Codex | `~/.codex/AGENTS.md` | spliced section |
| OpenCode | `~/.config/opencode/AGENTS.md` | spliced section |
| Gemini CLI | `~/.gemini/GEMINI.md` | spliced section |
| Cursor | `~/.cursor/rules/lazy-code.mdc` | whole file (`alwaysApply: true`) |
| Windsurf | `~/.codeium/windsurf/memories/global_rules.md` | spliced section |
| Cline | `~/Documents/Cline/Rules/lazy-code.md` | whole file |
| Kiro | `~/.kiro/steering/lazy-code.md` | whole file |
| Copilot | `<repo>/.github/copilot-instructions.md` | spliced section, `-Repo` only |
| generic | `<repo>/AGENTS.md` | spliced section, `-Repo` only |

Spliced sections live between `<!-- lazy-code:start -->` and `<!-- lazy-code:end -->`
and are replaced on re-run, so surrounding notes survive. Whole files that differ
are backed up to `<name>.bak` first.

Copilot reads no user-level instructions file, so it needs `-Repo` per repository.

## Updating

Edit `../SKILL.md`, regenerate `RULE.md` (drop the YAML frontmatter), re-run
`install.ps1`. Paths change as vendors move things — if a host stops picking the
rule up, check its current config location before assuming the script failed.

Verified against PowerShell 7.4.6 on Linux with a fake `$HOME`; the paths above
are Windows user-profile paths and were not exercised on the real host.
