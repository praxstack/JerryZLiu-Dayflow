# Design

## What this change actually ships

Layers for JerryZLiu/Dayflow#285 (tens of thousands of "Processing failed"
cards overflowing Daily recap):

1. **Stop creating the stack.** `replaceTimelineCardsInRange` used to preserve
   `category = System` cards from other batches. Overlapping failed batches
   therefore kept every previous error card and inserted a new one. Failed
   cards (`title = Processing failed`) in the replacement window are now
   always soft-deleted, regardless of `batch_id`. Policy:
   `TimelineReplacementPolicy.shouldSoftDeleteCard` / `replaceableCardsSQLPredicate`.
2. **Stop feeding them to models.** Generation context and recap `makeCardsText`
   drop those cards; recap input is still capped at 60k characters.
3. **Clean already-stored duplicates.** `StorageManager.migrate()` runs
   `historicalDuplicateFailedCardsSQL`, keeping the lowest id per
   `(day, start_ts, end_ts)` and soft-deleting the rest.

Dead unfiltered `makeCardsText` copies in `DailyRecapScheduler` were removed
so they cannot be wired up again.

## What this does not ship

- Changing Ollama/Gemma sliding-window `allCards = existingCards` rewrite
  (needed so lookback cards are not dropped on replace)
- Hard-deleting failed cards (soft-delete only, matching live replacement)
- `xcodebuild` in this Linux environment

## Verification

```
swift test --package-path tools/timeline-kernel
python3 tools/timeline-kernel/tests/test_failed_card_cleanup.py
```

macOS XCTest: `Dayflow/DayflowTests/TimelineReplacementPolicyTests.swift`
and `DayflowTests/DailyRecapGeneratorTests.testMakeCardsTextDropsProcessingFailedAndCapsLength`.
