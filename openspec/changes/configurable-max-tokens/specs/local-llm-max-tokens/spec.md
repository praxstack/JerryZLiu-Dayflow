# Spec Delta

## Purpose
OllamaProvider SHALL use 4000 max_tokens by default and SHALL honor a positive llmLocalMaxOutputTokens UserDefaults integer.

## ADDED Requirements

### Requirement: Local max_tokens is overridable
OllamaProvider SHALL use 4000 max_tokens by default and SHALL honor a positive llmLocalMaxOutputTokens UserDefaults integer.

#### Scenario: Override
- **WHEN** defaults contain llmLocalMaxOutputTokens = 32000
- **THEN** resolved max output tokens is 32000
