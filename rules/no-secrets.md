# No secrets in shared files

- Never write API keys, passwords, cookies, bearer tokens, browser session data,
  or `.env` values into this harness, the Obsidian vault, learnings, or docs.
  Replace any you meet with `<REDACTED>`.
- `env/env.yaml` in this repo is plaintext and synced to every machine: only
  non-secret switches go there.
