# Design

## What this change actually ships

Foundation-only Flow kernel used by the macOS app and by Linux `swift test`:

- `FlowAgentDecision` / `FlowParsedVerdict` / `FlowVerdictInterpreter.parse`
- `FlowOverlayMapping` for phase overlay events and agent nudge/praise policy
- `FlowNativeSnapshot` Codable + bridge-payload round-trip tests
- `FlowSessionMirrorCore` + `MockFlowBridge` (`FlowEventSink`) for Linux
  `FlowSessionMirrorTests` (idle→active overlay, break, hide, focus-change
  bridge events, quiet-mode nudge suppression). No ScreenCaptureKit.

App sources `FlowNativeState.swift`, `FlowVerdictInterpreter.swift`, and
`FlowSessionMirrorCore.swift` are symlinks into `tools/flow-kernel`.
`FlowDistractionAgent` calls `decode` + `interpret`; garbage replies still
skip `handle` so a flaky turn cannot close an off-task interval.
`FlowSessionMirror` (AppKit singleton) still owns timers, localization, and
the live webview bridge.

## What this does not ship

- Live Codex / ScreenCaptureKit tests
- Rewrite of the tick loop
- Driving the `@MainActor` `FlowSessionMirror.shared` singleton on Linux
- `xcodebuild` in this Linux Cloud Agent image

## Verification (this environment)

```
swift test --package-path tools/flow-kernel
```
