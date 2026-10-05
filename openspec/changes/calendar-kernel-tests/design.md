# Design

## What this change actually ships

A shared Foundation-only calendar kernel used by both the macOS app and
`dayflow-cli`:

- Source of truth: `Dayflow/Dayflow/Core/Shared/DayflowCalendar.swift`
- Linux/SwiftPM tests: `tools/dayflow-kernel` (path-depends on that folder)
- CLI `DayBoundary.swift` / `Categories.swift` are wrappers, not copies
- App `StorageDateHelpers.getDayInfoFor4AMBoundary` and
  `WeeklyDateRange.containing` delegate to the same types

Week windows use the app's Monday-first Gregorian calendar
(`firstWeekday = 2`, `minimumDaysInFirstWeek = 4`, `yearForWeekOfYear`) so
CLI timeline queries cannot drift from the weekly UI. The old CLI
weekday-arithmetic copy is gone.

## What this does not ship

- The CLI is not an Xcode target (plan 002 option A). Option B is the
  interim SwiftPM package.
- `xcodebuild` / `DayflowCalendarKernelTests` cannot be executed in this
  Linux Cloud Agent image. Those XCTest files are for macOS CI.
- CategoryStore write-path / UI is unchanged; only the CLI read-path list
  is shared.

## Risks

- App `DateFormatter.yyyyMMdd` still has no `en_US_POSIX` locale; kernel
  day keys do. Keys remain `yyyy-MM-dd` and should match.
- `tools/*` is gitignored except `dayflow-cli` and now `dayflow-kernel`.

## Verification (this environment)

```
swift test --package-path tools/dayflow-kernel
swift build --package-path tools/dayflow-cli
```
