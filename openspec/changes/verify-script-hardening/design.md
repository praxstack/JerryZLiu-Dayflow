# Design

## Context
Harden the existing bash verifier; do not rewrite it in Python.

## Goals / Non-Goals
- Goals: ship a focused, reviewable change that can merge independently of other overnight PRs.
- Non-goals: rewriting the macOS app UI, adding MCP servers, merging to main.

## Decisions
- bash + python3 only, no new runtime deps.

## Design review loop

### Principal engineer (round 1)
Keep DAYFLOW_DB fixture path. Use python3 -c for JSON assertions already in the script.

### Senior principal engineer (round 1)
MCP: timeout 5s, send initialize, require serverInfo.name == dayflow, then kill.

### Second senior principal engineer (round 2)
Approve.

### Decision
Approved.

## Risks / Trade-offs
MCP child must be killed even if jq/python fails.

## Migration Plan
None. Additive on a feature branch.

## Open Questions
None remaining for this scoped change.
