# Proposal

## Why
DayflowUITests target has no PBXFileSystemSynchronizedRootGroup, so UI test sources are not compiled and the xctest bundle has no executable.

## What Changes
- Add a synchronized root group for DayflowUITests mirroring DayflowTests.

## Capabilities

### New Capabilities
- `uitest-target-sources`: the DayflowUITests Xcode target compiles files in Dayflow/DayflowUITests.

### Modified Capabilities

## Impact
Dayflow/Dayflow.xcodeproj/project.pbxproj
