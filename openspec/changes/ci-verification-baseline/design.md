# Design

## What this change actually ships

Plan 001 verification baseline:

- `.github/workflows/ci.yml` `unit-tests` job on `macos-15` with
  `DEVELOPER_DIR=/Applications/Xcode_16.4.app/Contents/Developer` runs
  `xcodebuild test -only-testing:DayflowTests` and `swift build` for the CLI.
  Dayflow.xcodeproj is objectVersion 77; macos-14's Xcode 15.4 cannot open it.
  That job uses Xcode's Swift. There is **no** `setup-swift` pin on this
  workflow. Linux CLI tests with Swift **6.3.3** live on PR #7
  (`.github/workflows/cli.yml`), matching the Cloud Agent image.

README Contributing documents the xcodebuild one-liner and that xcodebuild is
macOS-only.

`ci.yml` comments point at `#7` `.github/workflows/cli.yml` for Linux CLI
tests. This workflow stays macOS-only so Darwin-only sources cannot go red.

## What this does not ship

- A Linux `swift build` / `swift test` / xcodebuild job on this branch
- DayflowUITests in CI
- Running xcodebuild in this Linux Cloud Agent image

## Verification (this environment)

`swift --version` here is 6.3.3. YAML parses. `xcodebuild` cannot run here.
