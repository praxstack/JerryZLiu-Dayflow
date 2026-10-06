// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "dayflow-kernel",
  platforms: [.macOS(.v13)],
  products: [
    .library(name: "DayflowCalendar", targets: ["DayflowCalendar"])
  ],
  targets: [
    .target(name: "DayflowCalendar"),
    .testTarget(
      name: "DayflowCalendarTests",
      dependencies: ["DayflowCalendar"]
    ),
  ]
)
