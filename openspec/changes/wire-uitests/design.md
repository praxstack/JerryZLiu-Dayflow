# Design

## Context
Mirror the existing DayflowTests synchronized-group wiring; no test code changes.

## Goals / Non-Goals
- Goals: ship a focused, reviewable change that can merge independently of other overnight PRs.
- Non-goals: rewriting the macOS app UI, adding MCP servers, merging to main.

## Decisions
- Add synchronized group + fileSystemSynchronizedGroups on the UITests target + top-level group child.

## Design review loop

### Principal engineer (round 1)
PE: this is a project-file bug, not a test rewrite.

### Senior principal engineer (round 1)
SPE: keep IDs unique (C4C1D2FF2DB56806007D5A56) as in the proven patch.

### Second senior principal engineer (round 2)
Approve.

### Decision
Approved.

## Risks / Trade-offs
Cannot execute UITests on Linux CI; correctness is pbxproj structure.

## Migration Plan
None. Additive on a feature branch.

## Open Questions
None remaining for this scoped change.
