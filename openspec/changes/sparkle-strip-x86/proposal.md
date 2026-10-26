# Proposal

## Why
JerryZLiu/Dayflow#309: Sparkle Autoupdate still ships an x86_64 slice, triggering Intel deprecation warnings on Apple Silicon even though Dayflow is arm64-only.

## What Changes
- Before codesigning Autoupdate in release_dmg.sh, lipo -thin arm64 when an x86_64 slice is present.

## Capabilities

### New Capabilities

### Modified Capabilities
- `sparkle-autoupdate-arch`: release packaging drops the unused Intel slice from Sparkle Autoupdate.

## Impact
scripts/release_dmg.sh
