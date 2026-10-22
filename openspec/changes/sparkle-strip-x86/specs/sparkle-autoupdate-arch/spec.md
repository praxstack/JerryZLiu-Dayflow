# Spec Delta

## Purpose
The DMG release script SHALL drop unused Mach-O slices from Sparkle Autoupdate and the bundled `dayflow` CLI when the main app is single-architecture, before codesign.

## ADDED Requirements

### Requirement: Helpers match the main app architecture on single-arch releases
When `Contents/MacOS/Dayflow` is exactly one architecture (`arm64` or `x86_64`), embedded helpers that still contain an unused slice SHALL be thinned to that architecture via a temp file in the helper's directory, permissions SHALL be preserved, then the existing codesign steps run.

#### Scenario: arm64-only app with universal Autoupdate
- **WHEN** the main executable is arm64-only and Autoupdate contains arm64 and x86_64
- **THEN** the script runs `lipo -thin arm64` to a temp file beside Autoupdate, replaces Autoupdate, restores mode, and codesigns

#### Scenario: Default DMG build is arm64-only
- **WHEN** `release_dmg.sh` runs without `RELEASE_ARCHS`
- **THEN** xcodebuild uses `ARCHS=arm64` and thinning removes x86_64 from Autoupdate and `Contents/Helpers/dayflow` when present

#### Scenario: Release fails if helpers stay mismatched
- **WHEN** thinning completes for a single-arch app
- **THEN** `lipo -archs` on Autoupdate and the bundled CLI matches the main executable or the script exits with an error
