# Design

## Context
Keep filtering/truncation inside makeCardsText so every provider path is covered.

## Goals / Non-Goals
- Goals: ship a focused, reviewable change that can merge independently of other overnight PRs.
- Non-goals: rewriting the macOS app UI, adding MCP servers, merging to main.

## Decisions
- Filter title == Processing failed.
- maxCharacters default 60_000, injectable for tests.

## Design review loop

### Principal engineer (round 1)
PE: 60k chars is a rough token ceiling, not a tokenizer. Good enough vs 92k duplicate failed cards.

### Senior principal engineer (round 1)
SPE: preserve String(localized:) empty-state from current main. Filter before sort. Do not change attempt budget (already shipped).

### Second senior principal engineer (round 2)
Approve. Tests live in Dayflow/DayflowTests so they compile.

### Decision
Approved.

## Risks / Trade-offs
Title-based filter is brittle if the app localizes that title; match current English failure title used in storage.

## Migration Plan
None. Additive on a feature branch.

## Open Questions
None remaining for this scoped change.
