# Project isolation

- A project's own `AGENTS.md` / authority chain outranks anything from this harness.
- Projects that are declared separate (for example BotTrade and forex-quant) never
  share gates, thresholds, backtests, model results, data, or credentials — not
  into each other's folders and not into shared `learnings/` or `docs/`.
- When unsure whether something is safe to share, keep it project-private.
