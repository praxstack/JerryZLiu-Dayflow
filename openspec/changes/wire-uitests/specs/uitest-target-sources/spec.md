# Spec Delta

## Purpose
The DayflowUITests native target SHALL reference a PBXFileSystemSynchronizedRootGroup whose path is DayflowUITests.

## ADDED Requirements

### Requirement: UITests target has a synchronized source group
The DayflowUITests native target SHALL reference a PBXFileSystemSynchronizedRootGroup whose path is DayflowUITests.

#### Scenario: Project file
- **WHEN** the pbxproj is inspected
- **THEN** DayflowUITests appears as a synchronized group on the UI test target
