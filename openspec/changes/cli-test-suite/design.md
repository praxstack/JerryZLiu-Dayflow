# Design

## Context
Library split is the smallest way to unit-test DayBoundary; MCP stays in the executable and is tested via subprocess.

## Goals / Non-Goals
- Goals: ship a focused, reviewable change that can merge independently of other overnight PRs.
- Non-goals: rewriting the macOS app UI, adding MCP servers, merging to main.

## Decisions
- DayflowCLICore contains DayBoundary only (public types/functions).
- Executable depends on DayflowCLICore and imports it.
- Swift tests: DayflowCLICoreTests.
- Python: tools/dayflow-cli/tests/test_cli.py.
- CI: .github/workflows/cli.yml with swift-actions/setup-swift.

## Design review loop

### Principal engineer (round 1)
Do not @testable-import the executable. Move only DayBoundary.swift into DayflowCLICore. JSONOut stays put because it calls fail()/telemetry.

### Senior principal engineer (round 1)
Python subprocess tests are acceptable on Linux Cloud Agents where XCTest GUI is unavailable. Keep them deterministic with the existing fixture generator.

### Second senior principal engineer (round 2)
Approve. Separate GitHub workflow cli.yml so this PR does not edit ci.yml.

### Decision
Approved after shrinking from a full library split of all sources.

## Risks / Trade-offs
Default-argument public API is a behavior-preserving move. MCP tests must not hang — kill the process after one tools/list round-trip.

## Migration Plan
None. Additive on a feature branch.

## Open Questions
None remaining for this scoped change.
