# Proposal

## Why
JerryZLiu/Dayflow#285: Daily Recap prompts can exceed model context when a day is flooded with duplicate "Processing failed" cards and there is no size guard.

## What Changes
- Filter cards titled "Processing failed" out of makeCardsText.
- Cap assembled cards text at 60_000 characters with an omitted-count notice.

## Capabilities

### New Capabilities

### Modified Capabilities
- `daily-recap-prompt`: recap card logs omit failed conversions and stay within a character budget.

## Impact
Dayflow/Dayflow/Core/AI/DailyRecapGenerator.swift, new DayflowTests.
