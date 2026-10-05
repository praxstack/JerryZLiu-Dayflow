# Spec Delta

## Purpose
Daily recap prompts MUST NOT be dominated by failed conversion cards or unbounded activity logs.

## ADDED Requirements

### Requirement: Failed conversion cards are omitted
makeCardsText MUST omit cards whose title is "Processing failed".

#### Scenario: Processing failed title
- **WHEN** makeCardsText is given cards including title "Processing failed"
- **THEN** those cards do not appear in the prompt text

### Requirement: Oversized logs truncate with a count
When remaining cards would exceed the character budget, makeCardsText MUST stop adding cards and MUST mention how many were omitted.

#### Scenario: Character budget
- **WHEN** remaining cards would exceed the character budget
- **THEN** the output stops adding cards and mentions how many were omitted
