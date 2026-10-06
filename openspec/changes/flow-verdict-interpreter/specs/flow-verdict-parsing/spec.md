# Spec Delta

## Purpose
Flow session nudges MUST NOT fire from unparseable model output. Overlay
policy for phase changes and agent actions MUST be testable without AppKit.

## ADDED Requirements

### Requirement: Unparseable replies are on-task
`parse` MUST return `.onTask` for replies that contain no JSON object.
`decode` MUST return nil for those replies so the agent does not flip
`lastReportedOffTask`.

#### Scenario: Garbage
- **WHEN** the model reply is not JSON
- **THEN** parse returns on-task, decode returns nil, and the agent does not nudge

### Requirement: First JSON object is the verdict
The interpreter MUST scan for the first top-level JSON object even when the model wraps it in markdown fences or prose.

#### Scenario: Fenced JSON
- **WHEN** the reply wraps a verdict object in markdown fences or prose
- **THEN** the interpreter still locates the object and reads status/action/message

### Requirement: Status and overlay are independent
`status: off_task` MUST set `isOffTask` even when `action` is `nudge` or `none`.
`action: nudge` MUST produce `.nudge` even when `status` is missing.

### Requirement: Overlay mapping matches FlowSessionMirror
Quiet mode, snooze, idle phase, and an already-visible nudge MUST suppress
agent overlay presentation. Repeat nudges in one incident MUST escalate.
