# Proposal

## Why
App and CLI duplicate 4 AM day/week rules. Before extracting a shared kernel (plans/002), lock current app behavior with characterization tests.

## What Changes
- Add DayflowTests for Date.getDayInfoFor4AMBoundary before/after 4 AM.
- Add DayflowTests for WeeklyDateRange Monday-before-4 AM week roll.

## Capabilities

### New Capabilities
- `calendar-boundaries`: Dayflow days start at 04:00 and weeks start Monday 04:00.

### Modified Capabilities

## Impact
Dayflow/DayflowTests only. No production logic change (characterization).
