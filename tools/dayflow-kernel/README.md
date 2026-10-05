# Dayflow calendar kernel

Foundation-only 4 AM day / Monday-week helpers shared by the macOS app and
`dayflow-cli`.

## Layout (plan 002 option B)

- Source of truth for SwiftPM: `Sources/DayflowCalendar/DayflowCalendar.swift`
- App compiles the same file via
  `Dayflow/Dayflow/Core/Shared/DayflowCalendar.swift` (symlink)
- CLI `Package.swift` depends on this package (`path: ../dayflow-kernel`)
- CLI `DayBoundary.swift` / `Categories.swift` are thin wrappers

```
swift test --package-path tools/dayflow-kernel
swift build --package-path tools/dayflow-cli
```

## Remaining (plan 002 option A — macOS / Xcode)

Folding `dayflow-cli` into `Dayflow.xcodeproj` as an app target that compiles
this kernel folder directly is **not** done here. Linux Cloud Agents cannot
edit/verify Xcode target membership with `xcodebuild`.

Until that lands:

- Do not copy `DayflowCalendar` logic back into CLI sources
- Keep the symlink in `Core/Shared/` so the synchronized Dayflow group picks
  the kernel up
- `Dayflow/DayflowTests/DayflowCalendarKernelTests.swift` is the macOS XCTest
  surface (unrun in this environment)
