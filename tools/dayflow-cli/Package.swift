// swift-tools-version:5.9
import PackageDescription

// Phase 1 of the Dayflow CLI: a standalone, read-only executable.
//
// It depends on the local `tools/dayflow-kernel` package (shared 4 AM calendar
// types) and nothing from the public Swift package index. SQLite comes from
// the system SDK on macOS and from libsqlite3 via a system-library target on
// Linux. Argument parsing is hand-rolled, so this builds with `swift build`
// alone and can later be folded into Dayflow.app as an Xcode target without
// dragging any package resolution along with it.
#if os(Linux)
let sqliteDependency: [Target.Dependency] = ["CSQLite"]
let sqliteTargets: [Target] = [
  .systemLibrary(
    name: "CSQLite",
    pkgConfig: "sqlite3",
    providers: [.apt(["libsqlite3-dev"]), .yum(["sqlite-devel"])]
  ),
]
#else
let sqliteDependency: [Target.Dependency] = []
let sqliteTargets: [Target] = []
#endif

let calendarDependency: Target.Dependency = .product(
  name: "DayflowCalendar", package: "dayflow-kernel")

let package = Package(
  name: "dayflow-cli",
  platforms: [.macOS(.v13)],
  dependencies: [
    .package(name: "dayflow-kernel", path: "../dayflow-kernel")
  ],
  targets: sqliteTargets + [
    .executableTarget(
      name: "dayflow",
      dependencies: [calendarDependency] + sqliteDependency,
      path: "Sources/dayflow"
    )
  ]
)
