// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "flow-kernel",
  platforms: [.macOS(.v13)],
  products: [
    .library(name: "DayflowFlow", targets: ["DayflowFlow"])
  ],
  targets: [
    .target(name: "DayflowFlow"),
    .testTarget(
      name: "DayflowFlowTests",
      dependencies: ["DayflowFlow"]
    ),
  ]
)
