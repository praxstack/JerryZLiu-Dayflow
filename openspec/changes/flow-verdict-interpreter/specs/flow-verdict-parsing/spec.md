# Spec Delta

## Purpose
Flow session nudges MUST NOT fire from unparseable model output.

## ADDED Requirements

### Requirement: Unparseable replies are on-task
The interpreter MUST return nil for replies that contain no JSON object, and the agent MUST treat that as on-task with no overlay action.

#### Scenario: Garbage
- **WHEN** the model reply is not JSON
- **THEN** parse returns nil and the agent does not nudge

### Requirement: First JSON object is the verdict
The interpreter MUST scan for the first top-level JSON object even when the model wraps it in markdown fences or prose.

#### Scenario: Fenced JSON
- **WHEN** the reply wraps a verdict object in markdown fences or prose
- **THEN** the interpreter still locates the object and reads status/action/message
