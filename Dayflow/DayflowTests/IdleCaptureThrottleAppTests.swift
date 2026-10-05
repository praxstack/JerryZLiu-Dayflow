import XCTest

@testable import Dayflow

/// macOS-app compile check for the idle-capture kernel types. The exhaustive
/// policy suite lives in `tools/idle-capture-kernel` and is what Linux CI runs.
final class IdleCaptureThrottleAppTests: XCTestCase {
  func testKernelTypesAreLinkedIntoTheAppModule() {
    XCTAssertEqual(IdleCaptureDefaults.throttledIntervalSeconds, 30)
    XCTAssertEqual(
      IdleCaptureThrottle.interval(baseInterval: 10, idleSeconds: 120),
      30
    )
    XCTAssertTrue(
      IdleCaptureThrottle.shouldCapture(
        now: Date(timeIntervalSince1970: 10),
        lastCapture: Date(timeIntervalSince1970: 0),
        interval: 10
      )
    )
    XCTAssertEqual(
      IdleCaptureDefaults.maxAllowedUncoveredGapSeconds,
      IdleBatchRules.maxAllowedUncoveredGapSeconds,
      "idle throttle cadence is tuned against IdleBatchClassifier's uncovered-gap limit"
    )
  }
}
