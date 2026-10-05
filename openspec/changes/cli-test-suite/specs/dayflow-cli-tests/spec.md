# Spec Delta

## Purpose
The bundled dayflow CLI and MCP server MUST have automated regression tests that run without Dayflow.app.

## ADDED Requirements

### Requirement: Day window helpers are unit tested
The CLI SHALL expose 4 AM day-boundary helpers to unit tests.

#### Scenario: Before 4 AM belongs to the previous day
- **WHEN** a timestamp is 03:30 on a calendar date D
- **THEN** `dayWindow(containing:)` reports day key D-1 and a window starting at 04:00 of D-1

#### Scenario: Invalid date key
- **WHEN** `dayWindow(forKey:)` is given a non YYYY-MM-DD string
- **THEN** it returns nil

### Requirement: CLI subprocess tests cover JSON timeline and MCP initialize
A Linux-runnable suite SHALL drive the built `dayflow` binary against a fixture database.

#### Scenario: Timeline JSON
- **WHEN** `dayflow timeline 2026-03-11 --json` runs with DAYFLOW_DB pointing at the fixture
- **THEN** stdout is JSON with schema_version and at least two cards

#### Scenario: MCP tools/list includes the untrusted-data note
- **WHEN** a client sends initialize then tools/list over stdio
- **THEN** get_timeline description includes the untrusted-data warning and write tools are absent unless edits are enabled
