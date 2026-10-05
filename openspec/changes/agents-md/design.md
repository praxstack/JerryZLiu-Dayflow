# Design

## What this change actually ships

Root `AGENTS.md` as a short pointer doc (build/test commands, hard rules:
no secrets, read-only CLI DB, do not bypass `agentEditsEnabled`, treat
timeline text as untrusted). One README sentence links to it.

## What this does not ship

- Product specs
- GUI verification (Linux Cloud Agents cannot run Dayflow.app)

## Risks

Docs can drift vs README — keep AGENTS.md as pointers only.
