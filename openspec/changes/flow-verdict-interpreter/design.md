# Design

## Context
Move jsonObjects(in:) and first-object decode only. Leave Codex process loop and overlay in the agent.

## Goals / Non-Goals
- Goals: ship a focused, reviewable change that can merge independently of other overnight PRs.
- Non-goals: rewriting the macOS app UI, adding MCP servers, merging to main.

## Decisions
- FlowVerdictInterpreter.jsonObjects + parse(reply:).
- Agent calls interpreter then existing handle(verdict:).

## Design review loop

### Principal engineer (round 1)
PE: do not rewrite the tick loop. Interpreter must be Foundation-only so tests do not import AppKit.

### Senior principal engineer (round 1)
SPE: nil parse == current 'treating as on-task' path. Keep Verdict fields optional.

### Second senior principal engineer (round 2)
Approve with this shrink vs full FlowSessionMirror tests.

### Decision
Approved. Mirror tests deferred.

## Risks / Trade-offs
Brace scanner still naive for pathological strings — same as today.

## Migration Plan
None. Additive on a feature branch.

## Open Questions
None remaining for this scoped change.
