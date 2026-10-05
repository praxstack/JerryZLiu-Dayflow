# Design

## What this change actually ships

Two layers for JerryZLiu/Dayflow#285 (tens of thousands of "Processing failed"
cards overflowing Daily recap):

1. **Stop creating the stack.** `replaceTimelineCardsInRange` used to preserve
   `category = System` cards from other batches. Overlapping failed batches
   therefore kept every previous error card and inserted a new one. Failed
   cards (`title = Processing failed`) in the replacement window are now
   always soft-deleted, regardless of `batch_id`. Policy:
   `TimelineReplacementPolicy.shouldSoftDeleteCard` / `replaceableCardsSQLPredicate`.
2. **Stop feeding them to models.** Generation context and recap `makeCardsText`
   drop those cards; recap input is still capped at 60k characters.

Dead unfiltered `makeCardsText` copies in `DailyRecapScheduler` were removed
so they cannot be wired up again.

## What this does not ship

- Deduping already-stored historical failed cards (no migration)
- Changing Ollama/Gemma sliding-window `allCards = existingCards` rewrite
  (needed so lookback cards are not dropped on replace)
- `xcodebuild` in this Linux environment

## Verification

`Dayflow/DayflowTests/TimelineReplacementPolicyTests.swift`
`DayflowTests/DailyRecapGeneratorTests.testMakeCardsTextDropsProcessingFailedAndCapsLength`
