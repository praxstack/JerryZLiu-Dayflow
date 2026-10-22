# Proposal

## Why
The repo has XCTest targets and a Swift CLI but .github contains only an issue template, so PRs merge unverified (plans/001).

## What Changes
- Add `.github/workflows/ci.yml` running DayflowTests on macos-14 and `swift build` for tools/dayflow-cli.
- Document local verification commands under README Contributing.

## Capabilities

### New Capabilities
- `ci-verification`: pull requests run unit tests and the CLI build.

### Modified Capabilities

## Impact
.github/workflows/ci.yml, README.md, plans/001-ci-verification-baseline.md status.
