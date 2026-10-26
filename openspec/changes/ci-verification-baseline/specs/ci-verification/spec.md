# Spec Delta

## Purpose
A pull request targeting main SHALL trigger a GitHub Actions workflow that runs DayflowTests on macOS and builds tools/dayflow-cli.

## ADDED Requirements

### Requirement: PRs run DayflowTests and build the CLI
A pull request targeting main SHALL trigger a GitHub Actions workflow that runs DayflowTests on macOS and builds tools/dayflow-cli.

#### Scenario: Pull request to main
- **WHEN** a contributor opens a PR against main
- **THEN** CI starts a macos job with xcodebuild test -only-testing:DayflowTests and a swift build of tools/dayflow-cli
