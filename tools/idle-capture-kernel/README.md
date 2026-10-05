# Dayflow idle-capture kernel

Foundation-only idle screenshot throttle shared by the macOS app and Linux
`swift test`. Implements the policy behind JerryZLiu/Dayflow #286 (capture
less often during long inactivity) without ScreenCaptureKit.

## Policy

Source of truth under `Sources/DayflowIdleCapture/IdleCaptureThrottle.swift`:

- `IdleCaptureDefaults` — 2 minute idle threshold, 30s throttled cadence
  (capped so IdleBatchClassifier's 30s uncovered-gap limit still holds)
- `IdleCapturePreferences` — on/off `UserDefaults` key, default enabled
- `IdleCaptureThrottle.interval` — idle heuristics (nil idle never throttles;
  never speeds up a slower user-chosen base interval)
- `IdleCaptureThrottle.shouldCapture` — time-since-last-capture gate
- `IdleCaptureThrottle.rescheduleInterval` / `decide` — one-tick decision
  for the recorder timer

| Consumer | How it compiles these files |
|----------|-----------------------------|
| macOS app (`Dayflow` target) | `Dayflow.xcodeproj` `PBXFileSystemSynchronizedRootGroup` `DayflowIdleCapture` → `../tools/idle-capture-kernel/Sources/DayflowIdleCapture` (`sourceTree = SOURCE_ROOT`). Same-module as `ScreenRecorder`. |
| `DayflowTests` | `IdleCaptureThrottleAppTests.swift` via the existing `DayflowTests` synchronized group. Types come from `@testable import Dayflow`. |
| Linux / CI | `swift test --package-path tools/idle-capture-kernel` |

```
swift test --package-path tools/idle-capture-kernel
```

Do not copy this policy back into `Dayflow/Dayflow/Core/Recording/` as a
second source file. Membership is declared in the pbxproj.

## Remaining (macOS-only)

`xcodebuild` is not run on Linux Cloud Agents. Residual risk: confirm on macOS
that the external synchronized group compiles these files into `Dayflow.app`
and that `-only-testing:DayflowTests/IdleCaptureThrottleAppTests` passes.

Still macOS-only (not in this kernel):

- `ScreenCaptureKit` / `SCScreenshotManager` in `ScreenRecorder`
- `CGEventSource.secondsSinceLastEventType` (`InputIdleSnapshot`) — the HID
  idle clock that feeds `idleSeconds` into this policy
- `DispatchSourceTimer` rebuild when `decide().rescheduleTo` is non-nil
- Settings > Storage toggle wiring in `StorageSettingsViewModel` /
  `SettingsStorageTabView` (AppKit / SwiftUI)
- Live idle classification in `IdleBatchClassifier` (uses stored
  `idleSecondsAtCapture` after frames are written)
