// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "timeline-kernel",
  platforms: [.macOS(.v13)],
  products: [
    .library(name: "DayflowTimeline", targets: ["DayflowTimeline"])
  ],
  targets: [
    .target(name: "DayflowTimeline"),
    .testTarget(
      name: "DayflowTimelineTests",
      dependencies: ["DayflowTimeline"]
    ),
  ]
)
