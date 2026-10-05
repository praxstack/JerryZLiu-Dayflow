# Design

## What this change actually ships

CLI test coverage toward plan 003:

- `DayflowCLICore` library: DayBoundary, Database (read-only SQLite), Queries,
  JSON envelope builders (`JSONOut.timelineEnvelope`)
- XCTest: DayBoundary, JSONOut keys, `fetchActivities` against the committed
  fixture generator
- Python subprocess tests for `timeline --json` and MCP `tools/list`
- GitHub workflow `.github/workflows/cli.yml` on Ubuntu with Swift **6.3.3**
  (aligned with the Cloud Agent image; previously pinned 6.0.3)

`printJSON` / `failJSON` stay in the executable because they call `fail()` and
`exit`.

## What this does not ship

- Mocked write-tool / Unix-socket integration tests
- Folding the CLI into the Xcode app target (plan 002 option A)
- `xcodebuild` (not available in this Linux environment)

## Verification (this environment)

```
swift test --package-path tools/dayflow-cli
bash tools/dayflow-cli/fixtures/create_fixture_db.sh
python3 tools/dayflow-cli/tests/test_cli.py
```
