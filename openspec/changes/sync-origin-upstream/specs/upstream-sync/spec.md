# Spec Delta

## Purpose
The fork SHALL detect when origin/main does not contain JerryZLiu/Dayflow main.

## ADDED Requirements

### Requirement: Origin must not lag upstream main
The fork SHALL detect when origin/main does not contain JerryZLiu/Dayflow main.

#### Scenario: Behind check
- **WHEN** the check script compares origin/main to upstream/main after fetch
- **THEN** it exits non-zero if any upstream/main commit is missing from origin/main, and exits zero when origin contains upstream
