import XCTest

@testable import DayflowIdleCapture

final class IdleCaptureThrottleTests: XCTestCase {
  func testActiveUserGetsBaseInterval() {
    let interval = IdleCaptureThrottle.interval(
      baseInterval: 10,
      idleSeconds: 0
    )
    XCTAssertEqual(interval, 10)
  }

  func testBelowThresholdStaysAtBaseInterval() {
    let interval = IdleCaptureThrottle.interval(
      baseInterval: 10,
      idleSeconds: 119
    )
    XCTAssertEqual(interval, 10)
  }

  func testAtThresholdSwitchesToThrottledInterval() {
    let interval = IdleCaptureThrottle.interval(
      baseInterval: 10,
      idleSeconds: 120
    )
    XCTAssertEqual(interval, 30)
  }

  func testLongIdleStaysAtThrottledInterval() {
    let interval = IdleCaptureThrottle.interval(
      baseInterval: 10,
      idleSeconds: 3600
    )
    XCTAssertEqual(interval, 30)
  }

  func testNilIdleSecondsGetsBaseInterval() {
    let interval = IdleCaptureThrottle.interval(
      baseInterval: 10,
      idleSeconds: nil
    )
    XCTAssertEqual(interval, 10)
  }

  func testDisabledPreferenceAlwaysReturnsBaseInterval() {
    let interval = IdleCaptureThrottle.interval(
      baseInterval: 10,
      idleSeconds: 600,
      enabled: false
    )
    XCTAssertEqual(interval, 10)
  }

  func testIdleThrottleNeverSpeedsUpSlowerBaseInterval() {
    let interval = IdleCaptureThrottle.interval(
      baseInterval: 60,
      idleSeconds: 600
    )
    XCTAssertEqual(interval, 60)
  }
}

final class IdleCaptureShouldCaptureTests: XCTestCase {
  private let t0 = Date(timeIntervalSince1970: 1_700_000_000)

  func testFirstCaptureAlwaysFires() {
    XCTAssertTrue(
      IdleCaptureThrottle.shouldCapture(now: t0, lastCapture: nil, interval: 10)
    )
  }

  func testSkipsWhenTimeSinceLastCaptureIsBelowInterval() {
    XCTAssertFalse(
      IdleCaptureThrottle.shouldCapture(
        now: t0.addingTimeInterval(9.999),
        lastCapture: t0,
        interval: 10
      )
    )
  }

  func testFiresWhenTimeSinceLastCaptureMeetsInterval() {
    XCTAssertTrue(
      IdleCaptureThrottle.shouldCapture(
        now: t0.addingTimeInterval(10),
        lastCapture: t0,
        interval: 10
      )
    )
  }

  func testFiresWhenTimeSinceLastCaptureExceedsInterval() {
    XCTAssertTrue(
      IdleCaptureThrottle.shouldCapture(
        now: t0.addingTimeInterval(30),
        lastCapture: t0,
        interval: 10
      )
    )
  }
}

final class IdleCaptureRescheduleTests: XCTestCase {
  func testNoRescheduleWhenIntervalUnchanged() {
    XCTAssertNil(
      IdleCaptureThrottle.rescheduleInterval(current: 10, target: 10)
    )
  }

  func testReschedulesWhenCrossingIdleThreshold() {
    XCTAssertEqual(
      IdleCaptureThrottle.rescheduleInterval(current: 10, target: 30),
      30
    )
  }

  func testReschedulesFromNilCurrent() {
    XCTAssertEqual(
      IdleCaptureThrottle.rescheduleInterval(current: nil, target: 10),
      10
    )
  }
}

final class IdleCaptureDecisionTests: XCTestCase {
  private let t0 = Date(timeIntervalSince1970: 1_700_000_000)

  func testDecideCombinesIdleIntervalAndElapsedTime() {
    let crossing = IdleCaptureThrottle.decide(
      now: t0.addingTimeInterval(10),
      lastCapture: t0,
      idleSeconds: 120,
      enabled: true,
      baseInterval: 10,
      scheduledInterval: 10
    )
    XCTAssertEqual(crossing.interval, 30)
    XCTAssertTrue(
      crossing.shouldCapture,
      "the threshold-crossing tick must still capture so the idle gap stays <= 30s"
    )
    XCTAssertEqual(crossing.rescheduleTo, 30)

    let earlyIdleTick = IdleCaptureThrottle.decide(
      now: t0.addingTimeInterval(10),
      lastCapture: t0,
      idleSeconds: 130,
      enabled: true,
      baseInterval: 10,
      scheduledInterval: 30
    )
    XCTAssertEqual(earlyIdleTick.interval, 30)
    XCTAssertFalse(earlyIdleTick.shouldCapture)
    XCTAssertNil(earlyIdleTick.rescheduleTo)
  }
}

final class IdleCaptureClassifierGapTests: XCTestCase {
  func testWorstCaseBlipDuringIdleStaysWithinClassifierGapLimit() {
    let interval = Int(IdleCaptureDefaults.throttledIntervalSeconds)
    var samples: [(capturedAt: Int, idleSeconds: Int)] = []
    var lastInputAt = -10_000
    let blipTick = interval * 6
    var t = interval
    while t <= 900 {
      if t == blipTick {
        lastInputAt = t - 1
      }
      samples.append((capturedAt: t, idleSeconds: t - lastInputAt))
      t += interval
    }

    let gap = largestUncoveredGapSeconds(samples: samples)
    XCTAssertLessThanOrEqual(
      gap, IdleCaptureDefaults.maxAllowedUncoveredGapSeconds,
      "worst-case blip-during-idle gap (\(gap)s) exceeds IdleBatchClassifier's limit"
    )
  }

  func testFullyIdleBatchAtThrottledCadenceHasZeroGap() {
    let interval = Int(IdleCaptureDefaults.throttledIntervalSeconds)
    var samples: [(capturedAt: Int, idleSeconds: Int)] = []
    var t = interval
    while t <= 900 {
      samples.append((capturedAt: t, idleSeconds: t + 600))
      t += interval
    }
    XCTAssertEqual(largestUncoveredGapSeconds(samples: samples), 0)
  }

  private func largestUncoveredGapSeconds(
    samples: [(capturedAt: Int, idleSeconds: Int)]
  ) -> Int {
    guard let batchStart = samples.first?.capturedAt, let batchEnd = samples.last?.capturedAt
    else { return 0 }

    var rawSegments: [(start: Int, end: Int)] = []
    for sample in samples {
      let start = max(batchStart, sample.capturedAt - sample.idleSeconds)
      let end = min(batchEnd, sample.capturedAt)
      if end > start { rawSegments.append((start: start, end: end)) }
    }
    let segments = rawSegments.sorted { lhs, rhs in
      lhs.start == rhs.start ? lhs.end < rhs.end : lhs.start < rhs.start
    }

    var merged: [(start: Int, end: Int)] = []
    for segment in segments {
      if var last = merged.last, segment.start <= last.end {
        last.end = max(last.end, segment.end)
        merged[merged.count - 1] = last
      } else {
        merged.append(segment)
      }
    }

    var gaps: [Int] = []
    var cursor = batchStart
    for segment in merged {
      if segment.start > cursor { gaps.append(segment.start - cursor) }
      cursor = max(cursor, segment.end)
    }
    if cursor < batchEnd { gaps.append(batchEnd - cursor) }
    return gaps.max() ?? 0
  }
}

final class IdleCapturePreferencesTests: XCTestCase {
  private var defaults: UserDefaults!
  private let suiteName = "idle-capture-throttle-tests"

  override func setUp() {
    super.setUp()
    defaults = UserDefaults(suiteName: suiteName)
    defaults.removePersistentDomain(forName: suiteName)
  }

  override func tearDown() {
    defaults.removePersistentDomain(forName: suiteName)
    defaults = nil
    super.tearDown()
  }

  func testDefaultsToEnabledWhenUnset() {
    XCTAssertTrue(IdleCapturePreferences.isEnabled(in: defaults))
  }

  func testPersistsDisabledAndReReadsIt() {
    IdleCapturePreferences.setEnabled(false, in: defaults)
    XCTAssertFalse(IdleCapturePreferences.isEnabled(in: defaults))
    XCTAssertEqual(defaults.object(forKey: IdleCapturePreferences.enabledKey) as? Bool, false)
  }

  func testPersistsReEnable() {
    IdleCapturePreferences.setEnabled(false, in: defaults)
    IdleCapturePreferences.setEnabled(true, in: defaults)
    XCTAssertTrue(IdleCapturePreferences.isEnabled(in: defaults))
  }
}
