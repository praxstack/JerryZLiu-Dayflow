# Design

## What this change actually ships

`OllamaProvider.resolvedMaxOutputTokens(from:fallback:)` reads UserDefaults key
`llmLocalMaxOutputTokens` (positive int; 0/missing → the call-site fallback,
default 4000). Settings > Providers persists that same key through
`OllamaProvider.persistMaxOutputTokens`.

Call sites that go through the resolver:

- Ollama chat / timeline `max_tokens` (fallback 4000)
- OpenAI-compatible `makeRequest` (fallback 8000)
- Local daily recap generation (fallback 8192)

Gemini, Gemma, and Gemini daily recap keep fixed caps and do not read the override.

Persisted overrides are clamped to 256–128000. Settings > Providers shows the
control only when the active provider is Local. Saving the displayed default
without an existing override is a no-op.

Override:

```
defaults write teleportlabs.com.Dayflow llmLocalMaxOutputTokens -int 32000
```

## What this does not ship

- `xcodebuild` / macOS UI verification in this Linux environment

## Verification

Resolver tests: `Dayflow/DayflowTests/OllamaProviderMaxTokensTests.swift`
Request tests: `OpenAICompatibleProviderTests.testMakeRequestHonorsConfiguredMaxTokens`
Settings binding: `ProvidersSettingsViewModelTests.testLocalMaxOutputTokensSaveWritesTheResolverKey`

Those XCTest files need macOS `xcodebuild`. Not run here.
