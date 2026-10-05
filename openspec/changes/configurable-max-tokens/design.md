# Design

## Context
UserDefaults int override, no Settings UI in this PR (smallest safe fix).

## Goals / Non-Goals
- Goals: ship a focused, reviewable change that can merge independently of other overnight PRs.
- Non-goals: rewriting the macOS app UI, adding MCP servers, merging to main.

## Decisions
- resolvedMaxOutputTokens(from: UserDefaults).
- ChatRequest and generateText defaults call the resolver.

## Design review loop

### Principal engineer (round 1)
PE: document defaults write in a comment. Do not add UI chrome.

### Senior principal engineer (round 1)
SPE: inject UserDefaults in the resolver function for tests; keep a standard wrapper for production.

### Second senior principal engineer (round 2)
Approve.

### Decision
Approved. No Settings UI.

## Risks / Trade-offs
Integer 0 means unset because UserDefaults.integer returns 0 for missing keys.

## Migration Plan
None. Additive on a feature branch.

## Open Questions
None remaining for this scoped change.
