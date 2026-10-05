# Dayflow calendar kernel

Foundation-only 4 AM day / Monday-week helpers shared by the macOS app and
`dayflow-cli`.

## Layout (plan 002)

Source of truth: `Sources/DayflowCalendar/DayflowCalendar.swift`

| Consumer | How it compiles this file |
|----------|---------------------------|
| macOS app (`Dayflow` target) | `Dayflow.xcodeproj` `PBXFileSystemSynchronizedRootGroup` `DayflowCalendar` → `../tools/dayflow-kernel/Sources/DayflowCalendar` (`sourceTree = SOURCE_ROOT`). Same-module as the rest of Dayflow; no `import DayflowCalendar` in app sources. |
| `DayflowTests` | `Dayflow/DayflowTests/DayflowCalendarKernelTests.swift` via the existing `DayflowTests` synchronized group. Types come from `@testable import Dayflow` (app target compiles the kernel). |
| `dayflow-cli` | SwiftPM `path: ../dayflow-kernel` product `DayflowCalendar`. `DayBoundary.swift` / `Categories.swift` are thin wrappers. |
| Linux / CI | `swift test --package-path tools/dayflow-kernel` |

```
swift test --package-path tools/dayflow-kernel
swift test --package-path tools/dayflow-cli
swift build --package-path tools/dayflow-cli
```

Do not copy `DayflowCalendar` logic back into CLI or app sources. Do not
reintroduce a symlink under `Dayflow/Dayflow/Core/Shared/` — Xcode 16
file-system synchronized groups do not reliably compile outgoing symlinks,
which is why membership is declared in the pbxproj instead.

## Remaining (macOS-only)

`xcodebuild` is not run on Linux Cloud Agents. Residual risk: confirm on macOS
that the external synchronized group compiles `DayflowCalendar.swift` into
`Dayflow.app` (`nm` / build log should list the file) and that
`-only-testing:DayflowTests/DayflowCalendarKernelTests` passes.

Folding `dayflow-cli` itself into `Dayflow.xcodeproj` as an executable target
is still not done; the app continues to embed the CLI via the existing
`swift build` script phase.
