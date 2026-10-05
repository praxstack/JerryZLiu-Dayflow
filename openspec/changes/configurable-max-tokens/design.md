# Design

## What this change actually ships

`OllamaProvider.resolvedMaxOutputTokens(from:fallback:)` reads UserDefaults key
`llmLocalMaxOutputTokens` (positive int; 0/missing → the call-site fallback,
default 4000).

Call sites that now go through that resolver:

- Ollama / OpenAI-compatible `max_tokens` (fallback 4000; was hardcoded 8000
  on the OpenAI-compatible path)
- Gemini `generateText` / dashboard chat (fallback 8192)
- Gemini activity cards + transcription (fallback 65536)
- Gemini connection test (fallback 4096)
- Gemma backup frame/summary/title/merge calls (fallbacks 2048/1024/256/512)
- Daily recap Gemini/local generation (fallback 8192)

Override:

```
defaults write teleportlabs.com.Dayflow llmLocalMaxOutputTokens -int 32000
```

No Settings UI in this PR (macOS screen, not verifiable here).

## What this does not ship

- A Settings slider
- `xcodebuild` verification in this Linux environment

## Verification

Resolver tests: `Dayflow/DayflowTests/OllamaProviderMaxTokensTests.swift`
Request tests: `OpenAICompatibleProviderTests.testMakeRequestHonorsConfiguredMaxTokens`

Those XCTest files need macOS `xcodebuild`. Not run here.
