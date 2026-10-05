# Proposal

## Why
Flow distraction agent parses model JSON with zero unit tests (plans/004). Unparseable replies must stay on-task/no-action.

## What Changes
- Extract brace-matching JSON object scan + first-object verdict decode into FlowVerdictInterpreter (Foundation-only).
- Add FlowVerdictInterpreterTests for valid, fenced, and garbage replies.

## Capabilities

### New Capabilities
- `flow-verdict-parsing`: Flow treats unparseable model replies as on-task with no overlay action.

### Modified Capabilities

## Impact
New Core/Flow/FlowVerdictInterpreter.swift, FlowDistractionAgent.swift, DayflowTests.
