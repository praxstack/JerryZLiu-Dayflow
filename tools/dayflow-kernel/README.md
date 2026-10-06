# Dayflow calendar kernel

Foundation-only 4 AM day / Monday-week helpers shared by the macOS app and
`dayflow-cli`.

## Layout (plan 002)

Source of truth: `Sources/DayflowCalendar/DayflowCalendar.swift`

| Consumer | How it compiles this file |
|----------|---------------------------|
| macOS app (`Dayflow` target) | `Dayflow.xcodeproj` `PBXFileSystemSynchronizedRootGroup` `DayflowCalendar` → `../tools/dayflow-kernel/Sources/DayflowCalendar` (`sourceTree = SOURCE_ROOT`). Same-module as the rest of Dayflow; no `import DayflowCalendar` in app sources. |
| `DayflowTests` | `Dayflow/DayflowTests/DayflowCalendarKernelTests.swift` via the existing `DayflowTests` synchronized group. Types come from `@testable import Dayflow` (app target compiles the kernel). |
| `dayflow-cli` Xcode tool | `PBXFileSystemSynchronizedRootGroup` `dayflow-cli` → `../tools/dayflow-cli/Sources/dayflow` plus `DayflowCalendarCLI` → the same kernel folder. Product name is `dayflow` (embedded at `Contents/Helpers/dayflow`). `import DayflowCalendar` is `#if canImport` so this same-module build works. |
| `dayflow-cli` SwiftPM | `path: ../dayflow-kernel` product `DayflowCalendar`. `DayBoundary.swift` / `Categories.swift` are thin wrappers. Linux/CI path. |
| Linux / CI | `swift test --package-path tools/dayflow-kernel` and `swift test --package-path tools/dayflow-cli` |

```
swift test --package-path tools/dayflow-kernel
swift test --package-path tools/dayflow-cli
swift build --package-path tools/dayflow-cli
```

Do not copy `DayflowCalendar` logic back into CLI or app sources. Do not
reintroduce a symlink under `Dayflow/Dayflow/Core/Shared/` — Xcode 16
file-system synchronized groups do not reliably compile outgoing symlinks,
which is why membership is declared in the pbxproj instead.

The Dayflow app target depends on `dayflow-cli` and copies the `dayflow`
product into `Contents/Helpers` (`PBXCopyFilesBuildPhase`, `CodeSignOnCopy`).
That replaced the previous `swift build` script phase.

## Confirm-on-Mac

`xcodebuild` is not available on Linux Cloud Agents. On a Mac with Xcode:

```bash
# 1. Project lists the new tool
xcodebuild -list -project Dayflow/Dayflow.xcodeproj
# Expect schemes/targets: Dayflow, dayflow-cli, DayflowTests, DayflowUITests

# 2. Build the CLI tool alone
xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme dayflow-cli \
  -configuration Debug -destination 'platform=macOS' build
# Expect BUILT_PRODUCTS_DIR/dayflow (PRODUCT_NAME=dayflow)

# 3. Build the app (must build CLI first via target dependency and embed it)
xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow \
  -configuration Debug -destination 'platform=macOS' build
APP=$(find ~/Library/Developer/Xcode/DerivedData -path '*/Build/Products/Debug/Dayflow.app' | head -1)
test -x "$APP/Contents/Helpers/dayflow"
file "$APP/Contents/Helpers/dayflow"
codesign -dv "$APP/Contents/Helpers/dayflow"

# 4. Kernel compiled into both products (build log / nm)
xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow \
  -configuration Debug -destination 'platform=macOS' build | tee /tmp/dayflow-build.log
grep DayflowCalendar.swift /tmp/dayflow-build.log
# Expect the file listed for Dayflow and for dayflow-cli

# 5. App kernel tests
xcodebuild test -project Dayflow/Dayflow.xcodeproj -scheme Dayflow \
  -destination 'platform=macOS' -only-testing:DayflowTests/DayflowCalendarKernelTests

# 6. Release embed (universal if ARCHS includes arm64 and x86_64)
xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow \
  -configuration Release -destination 'generic/platform=macOS' \
  ONLY_ACTIVE_ARCH=NO build
lipo -archs "$APP_RELEASE/Contents/Helpers/dayflow"
```

The previous embed script forced `swift build --arch arm64 --arch x86_64` for
Release. The Xcode tool now follows the project's `ARCHS` /
`ONLY_ACTIVE_ARCH`. Confirm Release is universal before a shipping archive.

## Residual risk (Linux cannot close)

- `xcodebuild` / `DayflowCalendarKernelTests` have not been run here.
- Copy Files + `CodeSignOnCopy` into `Contents/Helpers` is untested on macOS;
  RunningBoard rejects the app if the nested helper's signature does not match.
- `#if canImport(DayflowCalendar)` is the SPM vs same-module switch; a later
  local-package reference named `DayflowCalendar` in the Xcode graph would make
  `canImport` true while kernel sources are also compiled (duplicate types).
