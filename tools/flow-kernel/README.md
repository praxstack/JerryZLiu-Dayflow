# Dayflow Flow kernel

Foundation-only Flow verdict parsing, overlay mapping, and session-mirror
policy shared by the macOS app and Linux characterization tests.

## Layout (plan 004)

Source of truth under `Sources/DayflowFlow/`:

- `FlowVerdictInterpreter.swift` — `FlowAgentDecision`, JSON extract/decode,
  fail-safe parse, `FlowOverlayMapping`
- `FlowNativeState.swift` — snapshot, phase, overlay presentation types
- `FlowSessionMirrorCore.swift` — mockable overlay/session state machine

| Consumer | How it compiles these files |
|----------|-----------------------------|
| macOS app (`Dayflow` target) | `Dayflow.xcodeproj` `PBXFileSystemSynchronizedRootGroup` `DayflowFlow` → `../tools/flow-kernel/Sources/DayflowFlow` (`sourceTree = SOURCE_ROOT`). Same-module as `FlowDistractionAgent` / `FlowSessionMirror`; no extra import. |
| `DayflowTests` | `FlowVerdictInterpreterTests.swift` and `FlowNativeSnapshotTests.swift` via the existing `DayflowTests` synchronized group. Types come from `@testable import Dayflow`. |
| Linux / CI | `swift test --package-path tools/flow-kernel` |

```
swift test --package-path tools/flow-kernel
```

Do not copy interpreter/overlay/mirror-core logic back into
`Dayflow/Dayflow/Core/Flow/`. Do not reintroduce outgoing symlinks there —
two of the previous links were broken (`../../../../../tools/...` from
`Core/Flow/` walks out of the repo), and Xcode 16 synchronized groups do not
reliably compile outgoing symlinks. Membership is declared in the pbxproj.

AppKit / ScreenCaptureKit types (`FlowDistractionAgent`, `FlowSessionMirror`,
`FlowOverlayController`) stay in the app tree and call into this kernel.

## Remaining (macOS-only)

`xcodebuild` is not run on Linux Cloud Agents. Residual risk: confirm on macOS
that the external synchronized group compiles the three kernel files into
`Dayflow.app` and that
`-only-testing:DayflowTests/FlowVerdictInterpreterTests` and
`FlowNativeSnapshotTests` pass. Tick-loop / ScreenCaptureKit coverage is still
out of scope for this kernel.
