# Design

## What this change actually ships

CLI test coverage for plan 003:

- `DayflowCLICore` library: DayBoundary, Database (read-only SQLite), Queries,
  JSON envelopes, MCP `untrustedNote`, AgentBridge Unix-socket client
- XCTest: DayBoundary, JSONOut, Queries, MCP catalog, bridge protocol, in-process
  Unix-socket mock (`DAYFLOW_SOCK`)
- Python subprocess tests for `timeline --json`, MCP `tools/list` including
  `untrustedNote`, write tools gated on `DAYFLOW_EDITS_ENABLED`, and a mock
  Unix-socket `create_category` → `category_add` round trip
- GitHub workflow `.github/workflows/cli.yml` on Ubuntu with Swift **6.3.3**

`printJSON` / `failJSON` stay in the executable because they call `fail()` and
`exit`.

## What this does not ship

- Folding the CLI into the Xcode app target (plan 002 option A)
- Live Dayflow.app socket tests (out of scope; mocks only)
- `xcodebuild` (not available in this Linux environment)

## Verification (this environment)

```
swift test --package-path tools/dayflow-cli
bash tools/dayflow-cli/fixtures/create_fixture_db.sh
python3 tools/dayflow-cli/tests/test_cli.py
```
