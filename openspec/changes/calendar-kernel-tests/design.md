# Design

## Context
Characterization tests only; do not extract a shared SPM kernel in this PR (that is a later, larger change).

## Goals / Non-Goals
- Goals: ship a focused, reviewable change that can merge independently of other overnight PRs.
- Non-goals: rewriting the macOS app UI, adding MCP servers, merging to main.

## Decisions
- XCTest in Dayflow/DayflowTests/StorageDateHelpersTests.swift and WeeklyDateRangeBoundaryTests.swift.

## Design review loop

### Principal engineer (round 1)
PE: extracting a kernel now would touch CLI and app simultaneously and fight the CLI-tests PR. Tests-first is the plan's step 1.

### Senior principal engineer (round 1)
SPE: use Calendar.current like production so tests match StorageDateHelpers. Document TZ coupling.

### Second senior principal engineer (round 2)
2nd SPE: approve. Keep tests in Dayflow/DayflowTests so the synchronized Xcode group picks them up.

### Decision
Approved. Deferred shared kernel extraction.

## Risks / Trade-offs
Tests use Calendar.current; CI macos-14 TZ is UTC, still internally consistent.

## Migration Plan
None. Additive on a feature branch.

## Open Questions
None remaining for this scoped change.
