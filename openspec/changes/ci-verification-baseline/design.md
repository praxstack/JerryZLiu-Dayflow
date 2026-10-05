# Design

## What this change actually ships

Plan 001 verification baseline:

- `.github/workflows/ci.yml` `unit-tests` job on `macos-14` runs
  `xcodebuild test -only-testing:DayflowTests` and `swift build` for the CLI.
  That job uses Xcode's Swift. There is **no** `setup-swift` 6.0.3 pin on this
  workflow (PE note). The 6.0.3 pin lived on `.github/workflows/cli.yml` and
  is aligned to **6.3.3** on the CLI-tests PR, matching the Cloud Agent image.

README Contributing documents the xcodebuild one-liner and that xcodebuild is
macOS-only.

## What this does not ship

- A Linux `swift build` job on this branch. This tree still `import Darwin`s
  in `AgentUsageTelemetry.swift`, so an ubuntu-24.04 job would be red until
  the Darwin/Glibc telemetry from the CLI PR lands.
- DayflowUITests in CI
- `swift test` for the CLI (owned by the CLI-tests PR)
- Running xcodebuild in this Linux Cloud Agent image

## Verification (this environment)

`swift --version` here is 6.3.3. YAML parses. `xcodebuild` cannot run here.
