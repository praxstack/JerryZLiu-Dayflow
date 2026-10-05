# Spec Delta

## Purpose
Local and OpenAI-compatible chat completions SHALL honor `llmLocalMaxOutputTokens`.

## ADDED Requirements

### Requirement: Local max_tokens is overridable
OllamaProvider SHALL use 4000 max_tokens by default and SHALL honor a positive
llmLocalMaxOutputTokens UserDefaults integer.

#### Scenario: Override
- **WHEN** defaults contain llmLocalMaxOutputTokens = 32000
- **THEN** resolved max output tokens is 32000

### Requirement: OpenAI-compatible path uses the same cap
OpenAICompatibleProvider.makeRequest SHALL pass
OllamaProvider.resolvedMaxOutputTokens() instead of a hardcoded 8000.

### Requirement: Gemini and Gemma use the same resolver
GeminiDirectProvider and GemmaBackupProvider SHALL pass
OllamaProvider.resolvedMaxOutputTokens(fallback:) instead of bare integer
constants. Unset defaults keep each call site's original fallback.

#### Scenario: Override applies to Gemma frames
- **WHEN** llmLocalMaxOutputTokens is 32000
- **THEN** Gemma describe_frames uses 32000 rather than 2048

### Requirement: Settings writes the same key the resolver reads
Providers settings SHALL save a positive integer to
`OllamaProvider.maxOutputTokensDefaultsKey` (`llmLocalMaxOutputTokens`) and
SHALL reset by removing that key.

#### Scenario: Save from Settings
- **WHEN** the user saves 32000 in Settings > Providers
- **THEN** `resolvedMaxOutputTokens()` is 32000

#### Scenario: Reset from Settings
- **WHEN** the user resets the control
- **THEN** the key is absent and `resolvedMaxOutputTokens()` is 4000

