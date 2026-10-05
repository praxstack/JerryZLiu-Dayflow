# Proposal

## Why
JerryZLiu/Dayflow#246: local/OpenAI-compatible calls hardcode max_tokens at 4000, which truncates reasoning models (empty titles).

## What Changes
- Add llmLocalMaxOutputTokens UserDefaults override (int > 0) for OllamaProvider chat requests.
- Default remains 4000.

## Capabilities

### New Capabilities

### Modified Capabilities
- `local-llm-max-tokens`: local chat completions use a configurable max token cap.

## Impact
OllamaProvider+Networking.swift, DayflowTests.
