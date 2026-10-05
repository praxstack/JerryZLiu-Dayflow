# Spec Delta

## Purpose
The DMG release script SHALL thin Sparkle Autoupdate to arm64 when lipo reports an x86_64 slice, before codesign.

## ADDED Requirements

### Requirement: Autoupdate is thinned to arm64 when universal
The DMG release script SHALL thin Sparkle Autoupdate to arm64 when lipo reports an x86_64 slice, before codesign.

#### Scenario: Universal Autoupdate
- **WHEN** Autoupdate contains x86_64 and arm64
- **THEN** the script runs lipo -thin arm64 in place then codesigns
