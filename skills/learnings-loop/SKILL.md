---
name: learnings-loop
description: >
  Capture hard-won session experience as a dated, tagged note when a session
  hits real friction (you corrected or interrupted the agent, it retried a
  failing approach, or backtracked) or covered substantial ground — then
  recall relevant past notes before starting new non-trivial work. Use at the
  end of a session that fought a problem, and at the start of work that isn't
  trivial. Not for routine, friction-free sessions.
license: MIT (concept adapted from teamai-cli, github.com/Tencent/teamai-cli)
---

# Learnings loop

Adapted from teamai-cli's friction-scored session capture + recall subagent
(MIT, github.com/Tencent/teamai-cli), stripped down to a local,
no-dependency convention: no CLI, no git push, no LLM enrichment call, no
hook wiring. Two halves of one loop, run manually or on request.

## 1. Capture — end of a session worth remembering

Write a note only when the session actually hit friction, matching
teamai-cli's own bar so the vault doesn't fill up with routine sessions:

- you interrupted or corrected the agent's approach;
- the agent retried a failing tool/command more than once, or backtracked;
- you rejected a proposed change or plan;
- OR the session covered substantial ground (three or more distinct
  tools/files/subsystems) even without friction.

A quiet, one-shot session that went straight through is not worth a note.

### Where it goes — project isolation

- **Project-private** — `note/<Project>/Learnings/<slug>-<date>.md`, where
  `<Project>` is that project's own top-level folder in this vault (e.g.
  `BotTrade`, `MT5_Control_Room_Migration`, `Hermes`, `SCI-RIIP project`,
  `webapp-orchestrator`). Use for insights specific to that project's code,
  models, thresholds, or data.
- **Shared / cross-project** — `note/Skills/Learnings/<slug>-<date>.md`. Use
  for a pattern, tool, or workflow lesson useful regardless of project (e.g.
  "vendor X's promo pricing lapses on a date", "uv run pytest needs a
  Windows-host re-run after a Linux-container session").

**Never put project-private evidence in the shared folder.** Where a
project's own `AGENTS.md` draws a wall between it and another project (for
example, BotTrade and forex-quant are separate organisations per
`bottrade/AGENTS.md` §2), no gate, threshold, backtest, model result, or
credential from one crosses into the other's folder or into the shared one.
When unsure whether something is shared-safe, keep it project-private.

### Format

```markdown
---
title: "<short, specific to the problem or finding>"
date: <YYYY-MM-DD>
project: <top-level vault folder name, or `shared`>
tags: [tag1, tag2, tag3]
---

## What happened
The task, and what went wrong or took real effort.

## What fixed it / what to do differently
The actual resolution — not a restatement of the ladder or the brief.

## Watch for
Anything a future session should check before repeating this path.
```

Redact before writing: no API keys, tokens, credentials, or `.env` values,
even partial ones — replace with `<REDACTED>`. This is a plaintext vault
file, not a secrets store.

Keep it short — a paragraph or two per section, not a transcript. This is a
knowledge base, not a diary.

## 2. Recall — start of non-trivial work

Before starting a task that isn't trivial (multi-file change, unfamiliar
subsystem, anything that smells like a past problem), check for relevant
prior notes rather than re-discovering the fix:

1. Grep for keywords over `note/Skills/Learnings/` and, for the *current*
   project only, `note/<Project>/Learnings/` — never another project's
   folder.
2. Open the matches that look relevant and skim them; don't dump full
   content into the working context.
3. Judge relevance yourself — a keyword hit is a lead, not proof of
   coverage. A note titled close to your topic that doesn't actually address
   it is not a source; say so rather than forcing a fit.
4. Recalled notes are **context, never authority** — the same status the
   vault's own runbooks already have under `bottrade/AGENTS.md` §2:
   historical claims, not executable proof. A project's own `AGENTS.md` or
   authority chain outranks anything recalled here.

If nothing relevant turns up, say so in one line and move on — don't stall
looking for a match that isn't there.

## Why this shape, not the real tool

teamai-cli (npm, git-native, ~20 supported agents) does this at team scale:
git push → MR → pull, BM25 + graph-boost search over a codebase knowledge
graph, and hooks that auto-inject into every agent's session lifecycle. That
is the right shape for a multi-human team. For one person running a
multi-vendor agent roster across a few strictly-separated projects, the
useful parts are the *capture bar* and the *project-isolated recall*, not the
distribution machinery — installing the actual CLI would add hooks into
every agent config on the machine and a git remote to administer, for no one
else to pull from, plus a bundled template that defaults to Chinese-only
output. See `teamai-cli-scoped-adoption-2026-09-12.md` (Bottrade project
docs) for the full evaluation and what would change this call — e.g. a
second human joining a project.
