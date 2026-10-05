# Design

## What this change actually ships

A shared Foundation-only calendar kernel used by both the macOS app and
`dayflow-cli`:

- Source of truth for SwiftPM: `tools/dayflow-kernel/Sources/DayflowCalendar/DayflowCalendar.swift`
- App compiles it via `Dayflow.xcodeproj` synchronized group `DayflowCalendar`
- Xcode `dayflow-cli` tool compiles CLI sources plus the same kernel folder
- CLI `Package.swift` path-depends on `../dayflow-kernel` for Linux/CI;
  `DayBoundary.swift` / `Categories.swift` are wrappers, not copies
- App `StorageDateHelpers.getDayInfoFor4AMBoundary` and
  `WeeklyDateRange.containing` delegate to the same types
- CLI `Tests/DayflowKernelWiringTests` proves the executable package links
  `DayflowCalendar`

Week windows use the app's Monday-first Gregorian calendar
(`firstWeekday = 2`, `minimumDaysInFirstWeek = 4`, `yearForWeekOfYear`) so
CLI timeline queries cannot drift from the weekly UI. The old CLI
weekday-arithmetic copy is gone.

## What this does not ship

- `xcodebuild` / `DayflowCalendarKernelTests` in this Linux Cloud Agent image.
  Confirm-on-Mac steps are in `tools/dayflow-kernel/README.md`.
- CategoryStore write-path / UI is unchanged; only the CLI read-path list
  is shared.

## Risks

- App `DateFormatter.yyyyMMdd` still has no `en_US_POSIX` locale; kernel
  day keys do. Keys remain `yyyy-MM-dd` and should match.
- `tools/*` is gitignored except `dayflow-cli` and now `dayflow-kernel`.
- Nested helper signing: Copy Files `CodeSignOnCopy` into `Contents/Helpers`
  is untested here. The old script used `codesign --force --sign`.
- `#if canImport(DayflowCalendar)` must stay; compiling kernel sources into
  the Xcode tool means there is no `DayflowCalendar` module in that target.

## Verification (this environment)

```
swift test --package-path tools/dayflow-kernel
swift test --package-path tools/dayflow-cli
python3 -c '...'  # OpenStep parse of Dayflow.xcodeproj/project.pbxproj
```

Confirm-on-Mac is documented in `tools/dayflow-kernel/README.md`.

## Verification (this environment)

```
swift test --package-path tools/dayflow-kernel
swift test --package-path tools/dayflow-cli
```
