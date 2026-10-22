// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "idle-capture-kernel",
  platforms: [.macOS(.v13)],
  products: [
    .library(name: "DayflowIdleCapture", targets: ["DayflowIdleCapture"])
  ],
  targets: [
    .target(name: "DayflowIdleCapture"),
    .testTarget(
      name: "DayflowIdleCaptureTests",
      dependencies: ["DayflowIdleCapture"]
    ),
  ]
)
