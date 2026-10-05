# Tasks

- [x] 1. Add resolver + wire ChatRequest/callTextAPI/generateText defaults
- [x] 2. Add OllamaProviderMaxTokensTests
- [x] 3. OpenAICompatibleProvider.makeRequest uses the same resolver (not 8000)
- [x] 4. Gemini/Gemma maxOutputTokens go through the same resolver with per-call fallbacks
- [x] 5. Settings > Providers reads/writes llmLocalMaxOutputTokens via the same persist/resolver helpers
