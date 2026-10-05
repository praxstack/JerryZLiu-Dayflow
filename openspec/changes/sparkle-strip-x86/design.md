# Design

## Context
One lipo invocation in the existing sign loop; no Sparkle fork.

## Goals / Non-Goals
- Goals: ship a focused, reviewable change that can merge independently of other overnight PRs.
- Non-goals: rewriting the macOS app UI, adding MCP servers, merging to main.

## Decisions
- Guarded lipo -thin arm64 before codesign.

## Design review loop

### Principal engineer (round 1)
PE: only Autoupdate, not the whole Sparkle.framework, matching the issue.

### Senior principal engineer (round 1)
SPE: grep lipo -info for x86_64 so arm64-only builds are no-ops.

### Second senior principal engineer (round 2)
Approve.

### Decision
Approved.

## Risks / Trade-offs
Intel Dayflow builds would break if someone shipped x86 app with this script — Dayflow is arm64-only.

## Migration Plan
None. Additive on a feature branch.

## Open Questions
None remaining for this scoped change.
