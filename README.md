# AI Harness

Single source of truth for the skills, rules and docs every AI agent on this
machine uses. Distributed by [teamai-cli](https://github.com/Tencent/teamai-cli).

| Folder | Content | Reaches |
|---|---|---|
| `skills/<name>/SKILL.md` | Agent skills | Claude Code, Codex (via teamai), Antigravity (via link) |
| `rules/*.md` | Always-on rules | Claude Code (`~/.claude/rules`), Codex (see note) |
| `docs/` | Reference docs | on demand |
| `learnings/` | Lessons from sessions (shared) | recall |

## Flow

1. Edit here — in Obsidian (`TeamAI/` in the vault is a junction to this folder) or any editor.
2. `scripts/sync.ps1` — commit + push to GitHub.
3. The next agent session runs `teamai pull` from its SessionStart hook and gets the change.

This folder is the authoring copy. teamai keeps its own clone under
`~/.teamai/`; do not edit that one.

## Setup (once per machine)

```powershell
powershell -ExecutionPolicy Bypass -File D:\AI\harness\scripts\setup-teamai.ps1 -RepoUrl https://github.com/rijjina/ai-harness.git
```
