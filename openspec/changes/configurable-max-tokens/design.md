# Design

## What this change actually ships

`OllamaProvider.resolvedMaxOutputTokens(from:)` reads UserDefaults key
`llmLocalMaxOutputTokens` (positive int; 0/missing → 4000).

`OllamaProvider.callTextAPI` / `generateText` already pass that value.
`OpenAICompatibleProvider.makeRequest` now uses the same resolver instead of
hardcoding `max_tokens: 8000` (JerryZLiu/Dayflow#246, LiteLLM / custom
OpenAI-compatible endpoints).

Override:

```
defaults write teleportlabs.com.Dayflow llmLocalMaxOutputTokens -int 32000
```

No Settings UI in this PR.

## What this does not ship

- A Settings slider
- Changing Gemini / Gemma `maxOutputTokens` constants
- `xcodebuild` verification in this Linux environment

## Verification

Resolver tests: `Dayflow/DayflowTests/OllamaProviderMaxTokensTests.swift`
Request tests: `OpenAICompatibleProviderTests.testMakeRequestHonorsConfiguredMaxTokens`

Those XCTest files need macOS `xcodebuild`. Not run here.
