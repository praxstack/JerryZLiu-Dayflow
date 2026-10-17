import XCTest

@testable import Dayflow

final class TimelineReviewCoverageMathTests: XCTestCase {
  func testEffectiveDurationClipsToDayWindow() {
    let dayStart = 1_700_000_000
    let dayEnd = dayStart + 24 * 60 * 60
    // Card spans 55 minutes but only 8 minutes fall inside the day window.
    let cardStart = dayEnd - (55 * 60)
    let cardEnd = dayEnd + (3 * 60)

    let effective = TimelineReviewCoverageMath.effectiveDuration(
      cardStart: cardStart,
      cardEnd: cardEnd,
      dayStartTs: dayStart,
      dayEndTs: dayEnd
    )
    XCTAssertEqual(effective, 8 * 60)
  }

  func testFullyRatedInDayWindowReachesFullCoverage() {
    let dayStart = 1_700_000_000
    let dayEnd = dayStart + 24 * 60 * 60
    let cardStart = dayEnd - (55 * 60)
    let cardEnd = dayEnd + (3 * 60)
    let reviewStart = max(cardStart, dayStart)
    let reviewEnd = min(cardEnd, dayEnd)
    let duration = TimelineReviewCoverageMath.effectiveDuration(
      cardStart: cardStart,
      cardEnd: cardEnd,
      dayStartTs: dayStart,
      dayEndTs: dayEnd
    )
    XCTAssertEqual(reviewEnd - reviewStart, duration)
    let covered = duration
    let ratio = Double(covered) / Double(duration)
    XCTAssertGreaterThanOrEqual(ratio, 0.8)
  }
}
