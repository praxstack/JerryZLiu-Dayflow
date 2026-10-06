# Dayflow Flow kernel

Foundation-only Flow verdict parsing, overlay mapping, session-mirror
policy, and a timer-free tick/deadline loop shared by the macOS app and
Linux characterization tests.

## Layout (plan 004)

Source of truth under `Sources/DayflowFlow/`:

- `FlowVerdictInterpreter.swift` — `FlowAgentDecision`, JSON extract/decode,
  fail-safe parse, `FlowOverlayMapping`
- `FlowNativeState.swift` — snapshot, phase, overlay presentation types
- `FlowSessionMirrorCore.swift` — mockable overlay/session state machine
- `FlowTickLoop.swift` — `FlowTickPolicy` plus injected clock/scheduler loop

| Consumer | How it compiles these files |
|----------|-----------------------------|
| macOS app (`Dayflow` target) | `Dayflow.xcodeproj` `PBXFileSystemSynchronizedRootGroup` `DayflowFlow` → `../tools/flow-kernel/Sources/DayflowFlow` (`sourceTree = SOURCE_ROOT`). Same-module as `FlowDistractionAgent` / `FlowSessionMirror`; no extra import. |
| `DayflowTests` | `FlowVerdictInterpreterTests.swift` and `FlowNativeSnapshotTests.swift` via the existing `DayflowTests` synchronized group. Types come from `@testable import Dayflow`. |
| Linux / CI | `swift test --package-path tools/flow-kernel` |

```
swift test --package-path tools/flow-kernel
```

Do not copy interpreter/overlay/mirror-core/tick-loop logic back into
`Dayflow/Dayflow/Core/Flow/`. Do not reintroduce outgoing symlinks there —
two of the previous links were broken (`../../../../../tools/...` from
`Core/Flow/` walks out of the repo), and Xcode 16 synchronized groups do not
reliably compile outgoing symlinks. Membership is declared in the pbxproj.

`FlowSessionMirror` and `FlowDistractionAgent` call `FlowTickPolicy` for
begin/finish/deadline decisions. AppKit / ScreenCaptureKit / live Codex stay
in the app tree.

## Remaining (macOS-only)

`xcodebuild` is not run on Linux Cloud Agents. Residual risk: confirm on macOS
that the external synchronized group compiles the kernel files into
`Dayflow.app` and that
`-only-testing:DayflowTests/FlowVerdictInterpreterTests` and
`FlowNativeSnapshotTests` pass.

Still macOS-only (not in this kernel):

- ScreenCaptureKit screenshot / OCR in `FlowDistractionAgent`
- Live Codex CLI process
- Foundation `Timer`s on `FlowSessionMirror.shared` (deadline, toast, break
  overlay) and `FlowDistractionAgent.shared` (tick cadence)
