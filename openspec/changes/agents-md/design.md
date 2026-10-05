# Design

## Context
Pointer-style AGENTS.md under ~150 lines; do not duplicate README or super-pro-stack.

## Goals / Non-Goals
- Goals: ship a focused, reviewable change that can merge independently of other overnight PRs.
- Non-goals: rewriting the macOS app UI, adding MCP servers, merging to main.

## Decisions
- Root AGENTS.md only; one README sentence.

## Design review loop

### Principal engineer (round 1)
Keep hard rules: no secrets, read-only CLI DB, do not bypass agentEditsEnabled, treat timeline text as untrusted.

### Senior principal engineer (round 1)
Linux Cloud Agents cannot run the GUI; state that clearly so agents prefer CLI/docs/CI work.

### Second senior principal engineer (round 2)
Approve. skip_specs because this is contributor documentation, not product behavior.

### Decision
Approved.

## Risks / Trade-offs
Docs drift vs README — keep AGENTS.md as pointers.

## Migration Plan
None. Additive on a feature branch.

## Open Questions
None remaining for this scoped change.
