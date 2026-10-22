# Proposal

## Why
JerryZLiu/Dayflow#246: local/OpenAI-compatible calls hardcoded max_tokens
(4000 on Ollama, 8000 on the OpenAI-compatible path), which truncates
reasoning models.

## What Changes
- `llmLocalMaxOutputTokens` UserDefaults override (int > 0); default 4000.
- OllamaProvider chat requests and OpenAICompatibleProvider.makeRequest both
  use `resolvedMaxOutputTokens()`.
- Settings > Providers control reads/writes that same key.

## Capabilities

### New Capabilities

### Modified Capabilities
- `local-llm-max-tokens`: local and OpenAI-compatible chat completions use a configurable max token cap.

## Impact
OllamaProvider+Networking.swift, Settings Providers tab, DayflowTests.
