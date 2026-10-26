// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "openai-compatible-kernel",
  platforms: [.macOS(.v13)],
  products: [
    .library(name: "DayflowOpenAICompatible", targets: ["DayflowOpenAICompatible"])
  ],
  targets: [
    .target(name: "DayflowOpenAICompatible"),
    .testTarget(
      name: "DayflowOpenAICompatibleTests",
      dependencies: ["DayflowOpenAICompatible"]
    ),
  ]
)
