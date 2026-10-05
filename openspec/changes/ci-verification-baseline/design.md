# Design

## Context
Implement plans/001 CI baseline without silently disabling tests.

## Goals / Non-Goals
- Goals: ship a focused, reviewable change that can merge independently of other overnight PRs.
- Non-goals: rewriting the macOS app UI, adding MCP servers, merging to main.

## Decisions
- Single macos-14 job as in plans/001.
- README subsection under Contributing.

## Design review loop

### Principal engineer (round 1)
Follow the plan YAML closely. Do not add continue-on-error. UITests stay out of v1.

### Senior principal engineer (round 1)
macos-14 minutes are costly but required for xcodebuild. A second Linux job would conflict with the CLI-tests PR; keep this workflow to the plan's macos job plus CLI build on the same runner (Xcode includes Swift).

### Second senior principal engineer (round 2)
Approve. Linux swift test belongs in a separate workflow file owned by the CLI-tests change.

### Decision
Approved. Workflow file is ci.yml only.

## Risks / Trade-offs
First run may fail if existing tests are red — that is a reported outcome, not a reason to skip tests.

## Migration Plan
None. Additive on a feature branch.

## Open Questions
None remaining for this scoped change.
