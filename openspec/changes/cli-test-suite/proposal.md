# Proposal

## Why
dayflow-cli has no test target. Argument parsing, 4 AM day windows, JSON envelopes, and MCP tool lists can regress without detection (plans/003).

## What Changes
- Extract DayBoundary into a DayflowCLICore library target so date helpers are unit-testable.
- Add SwiftPM tests for day windows, durations, invalid dates.
- Add a Python CLI/MCP subprocess suite against the fixture DB (Linux-runnable).
- Add `.github/workflows/cli.yml` running `swift test` and the Python suite on Ubuntu with Swift.

## Capabilities

### New Capabilities
- `dayflow-cli-tests`: automated tests for the bundled CLI and MCP stdio server.

### Modified Capabilities

## Impact
tools/dayflow-cli Package.swift, Sources layout, Tests/, tools/dayflow-cli/tests/, .github/workflows/cli.yml, plans/003.
