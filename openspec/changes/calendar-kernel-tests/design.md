# Design

## What this change actually ships

A shared Foundation-only calendar kernel used by both the macOS app and
`dayflow-cli`:

- Source of truth for SwiftPM: `tools/dayflow-kernel/Sources/DayflowCalendar/DayflowCalendar.swift`
- App compiles it via `Dayflow/Dayflow/Core/Shared/DayflowCalendar.swift` (symlink)
- CLI `Package.swift` path-depends on `../dayflow-kernel`; `DayBoundary.swift` /
  `Categories.swift` are wrappers, not copies
- App `StorageDateHelpers.getDayInfoFor4AMBoundary` and
  `WeeklyDateRange.containing` delegate to the same types
- CLI `Tests/DayflowKernelWiringTests` proves the executable package links
  `DayflowCalendar`

Week windows use the app's Monday-first Gregorian calendar
(`firstWeekday = 2`, `minimumDaysInFirstWeek = 4`, `yearForWeekOfYear`) so
CLI timeline queries cannot drift from the weekly UI. The old CLI
weekday-arithmetic copy is gone.

## What this does not ship

- Folding the CLI into `Dayflow.xcodeproj` as an app target (plan 002 option A).
  Documented in `tools/dayflow-kernel/README.md`. Linux cannot verify Xcode
  target membership.
- `xcodebuild` / `DayflowCalendarKernelTests` in this Linux Cloud Agent image.
- CategoryStore write-path / UI is unchanged; only the CLI read-path list
  is shared.

## Risks

- App `DateFormatter.yyyyMMdd` still has no `en_US_POSIX` locale; kernel
  day keys do. Keys remain `yyyy-MM-dd` and should match.
- `tools/*` is gitignored except `dayflow-cli` and now `dayflow-kernel`.

## Verification (this environment)

```
swift test --package-path tools/dayflow-kernel
swift test --package-path tools/dayflow-cli
```
