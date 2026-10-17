# Spec Delta

## Purpose
Local and OpenAI-compatible chat completions SHALL honor `llmLocalMaxOutputTokens`.
Gemini and Gemma keep their existing fixed per-call caps.

## ADDED Requirements

### Requirement: Local max_tokens is overridable
OllamaProvider SHALL use 4000 max_tokens by default and SHALL honor a positive
llmLocalMaxOutputTokens UserDefaults integer clamped to 256–128000.

#### Scenario: Override
- **WHEN** defaults contain llmLocalMaxOutputTokens = 32000
- **THEN** resolved max output tokens is 32000

### Requirement: OpenAI-compatible path uses the same cap
OpenAICompatibleProvider.makeRequest SHALL pass
`OllamaProvider.resolvedMaxOutputTokens(fallback: 8000)` instead of a bare 4000 default.

### Requirement: Gemini and Gemma stay on fixed caps
GeminiDirectProvider and GemmaBackupProvider SHALL NOT read
`llmLocalMaxOutputTokens`; they keep their historical integer fallbacks.

### Requirement: Settings writes the same key the resolver reads
Providers settings (local provider only) SHALL save a positive integer to
`OllamaProvider.maxOutputTokensDefaultsKey` (`llmLocalMaxOutputTokens`) and
SHALL reset by removing that key.

#### Scenario: Save from Settings
- **WHEN** the user saves 32000 in Settings > Providers (local provider)
- **THEN** `resolvedMaxOutputTokens()` is 32000

#### Scenario: Reset from Settings
- **WHEN** the user resets the control
- **THEN** the key is absent and `resolvedMaxOutputTokens()` is 4000
