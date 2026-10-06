# Spec Delta

## Purpose
Dayflow calendar math MUST treat a day as 04:00-04:00 and a week as Monday 04:00-Monday 04:00.

## ADDED Requirements

### Requirement: Day rolls at 04:00
A timestamp before 04:00 local time MUST belong to the previous calendar day's Dayflow day.

#### Scenario: 03:30
- **WHEN** the local time is 03:30 on 2026-03-11
- **THEN** getDayInfoFor4AMBoundary reports day string 2026-03-10

#### Scenario: 04:00
- **WHEN** the local time is 04:00 on 2026-03-11
- **THEN** getDayInfoFor4AMBoundary reports day string 2026-03-11

### Requirement: Week rolls at Monday 04:00
A timestamp on Monday before 04:00 local time MUST belong to the previous Dayflow week.

#### Scenario: Monday 03:30
- **WHEN** the local time is Monday 03:30
- **THEN** WeeklyDateRange.containing returns the prior week's Monday 04:00 start
