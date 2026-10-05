# Design

## What this change actually ships

Foundation-only Flow kernel used by the macOS app and by Linux `swift test`:

- `FlowAgentDecision` / `FlowParsedVerdict` / `FlowVerdictInterpreter.parse`
- `FlowOverlayMapping` for phase overlay events and agent nudge/praise policy
- `FlowNativeSnapshot` Codable + bridge-payload round-trip tests

App sources `Dayflow/Dayflow/Core/Flow/FlowNativeState.swift` and
`FlowVerdictInterpreter.swift` are symlinks into `tools/flow-kernel`.
`FlowDistractionAgent` calls `decode` + `interpret`; garbage replies still
skip `handle` so a flaky turn cannot close an off-task interval.
`FlowSessionMirror.apply` / `agentNudge` / `agentPraise` / `simulateDistraction`
consult `FlowOverlayMapping` for overlay policy. Timers and AppKit stay in
the mirror.

## What this does not ship

- Live Codex / ScreenCaptureKit tests
- Rewrite of the tick loop
- `FlowSessionMirrorTests` with a mock `FlowBridgeForwarding` (optional in
  plan 004; still TODO — needs `@MainActor` and the shared singleton)
- `xcodebuild` in this Linux Cloud Agent image

## Verification (this environment)

```
swift test --package-path tools/flow-kernel
```
