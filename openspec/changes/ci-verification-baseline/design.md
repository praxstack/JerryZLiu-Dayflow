# Design

## What this change actually ships

Plan 001 verification baseline:

- `.github/workflows/ci.yml` `unit-tests` job on `macos-14` runs
  `xcodebuild test -only-testing:DayflowTests` and `swift build` for the CLI.
  That job uses Xcode's Swift. There is **no** `setup-swift` 6.0.3 pin on this
  workflow. The 6.0.3 pin lived on `.github/workflows/cli.yml` and is aligned
  to **6.3.3** on the CLI-tests PR (#7), matching the Cloud Agent image.

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
