# Dayflow OpenAI-compatible kernel

Foundation-only OpenAI-compatible configuration, screenshot budget, and HTTP
error formatting shared by the macOS app and Linux `swift test`. Implements
the policy behind JerryZLiu/Dayflow #385 (configurable image batch size)
without AppKit, SwiftUI, or the live HTTP provider.

## Policy

Source of truth under
`Sources/DayflowOpenAICompatible/OpenAICompatibleConfiguration.swift`:

- `OpenAICompatibleScreenshotBudget` — clamp 1...15, default 15; even sample
  that keeps first and last frames
- `OpenAICompatibleHTTPErrorFormatter` — prefer gateway `error.message`
- `OpenAICompatibleEndpoint` — `/v1/chat/completions` URL normalization
- `OpenAICompatibleConfiguration` / `Preferences` / `RuntimeConfiguration` —
  Codable persistence and injected runtime (bearer trim, image budget)

| Consumer | How it compiles these files |
|----------|-----------------------------|
| macOS app (`Dayflow` target) | `Dayflow.xcodeproj` `PBXFileSystemSynchronizedRootGroup` `DayflowOpenAICompatible` → `../tools/openai-compatible-kernel/Sources/DayflowOpenAICompatible` (`sourceTree = SOURCE_ROOT`). Same-module as `OpenAICompatibleProvider`. |
| `DayflowTests` | `OpenAICompatibleConfigurationTests.swift` / `OpenAICompatibleProviderTests.swift` via the existing `DayflowTests` synchronized group. Types come from `@testable import Dayflow`. |
| Linux / CI | `swift test --package-path tools/openai-compatible-kernel` |

```
swift test --package-path tools/openai-compatible-kernel
```

Do not copy this policy back into `Dayflow/Dayflow/Core/AI/` as a second
source file. Membership is declared in the pbxproj.

## Remaining (macOS-only)

`xcodebuild` is not run on Linux Cloud Agents. Residual risk: confirm on macOS
that the external synchronized group compiles these files into `Dayflow.app`
and that `-only-testing:DayflowTests/OpenAICompatibleProviderTests` passes.

Still macOS-only (not in this kernel):

- `OpenAICompatibleProvider` (timeline prompts, screenshot JPEG encoding)
- `OllamaProvider` HTTP transport / `makeChatURLRequest`
- Keychain API-key storage
- SwiftUI setup and Settings providers UI
