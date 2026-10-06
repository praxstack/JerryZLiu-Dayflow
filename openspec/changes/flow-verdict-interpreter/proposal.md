# Proposal

## Why
Flow distraction agent parses model JSON and drives overlay nudges with no
characterization of `FlowAgentDecision` or overlay policy (plans/004).
Unparseable replies must stay on-task/no-action.

## What Changes
- Foundation-only kernel: verdict parse → `FlowAgentDecision`, overlay policy
  → `FlowOverlayMapping`.
- Agent and session mirror call that kernel; AppKit timers stay in the mirror.
- Linux `swift test --package-path tools/flow-kernel` plus Dayflow XCTest files.

## Capabilities

### New Capabilities
- `flow-verdict-parsing`: Flow treats unparseable model replies as on-task with no overlay action.

### Modified Capabilities

## Impact
`tools/flow-kernel`, FlowDistractionAgent, FlowSessionMirror, DayflowTests.
