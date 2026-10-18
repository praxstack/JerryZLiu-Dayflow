import XCTest

@testable import Dayflow

final class TimelineReviewCoverageMathTests: XCTestCase {
  private let dayStart = 1_700_000_000
  private var dayEnd: Int { dayStart + 24 * 60 * 60 }

  /// 3:52–4:47 style card on the day ending at `dayEnd`.
  private var boundaryCardStart: Int { dayEnd - (8 * 60) }
  private var boundaryCardEnd: Int { dayEnd + (47 * 60) }

  func testEffectiveDurationClipsToDayWindow() {
    let effective = TimelineReviewCoverageMath.effectiveDuration(
      cardStart: boundaryCardStart,
      cardEnd: boundaryCardEnd,
      dayStartTs: dayStart,
      dayEndTs: dayEnd
    )
    XCTAssertEqual(effective, 8 * 60)
  }

  func testInDayRatingOnBoundaryCardReachesFullCoverage() {
    let rating = TimelineReviewRatingSegment(
      id: 1,
      startTs: boundaryCardStart,
      endTs: dayEnd,
      rating: "productive"
    )
    let merged = TimelineReviewCoverageMath.mergeCoverageSegments(
      segments: [rating],
      dayStartTs: dayStart,
      dayEndTs: dayEnd
    )
    let duration = TimelineReviewCoverageMath.effectiveDuration(
      cardStart: boundaryCardStart,
      cardEnd: boundaryCardEnd,
      dayStartTs: dayStart,
      dayEndTs: dayEnd
    )
    var segmentIndex = 0
    let covered = TimelineReviewCoverageMath.overlapSeconds(
      start: boundaryCardStart,
      end: dayEnd,
      segments: merged,
      segmentIndex: &segmentIndex
    )
    XCTAssertEqual(covered, duration)
    XCTAssertGreaterThanOrEqual(Double(covered) / Double(duration), 0.8)
  }

  func testPostBoundaryRatingDoesNotSatisfyInDayCoverage() {
    let rating = TimelineReviewRatingSegment(
      id: 1,
      startTs: dayEnd,
      endTs: boundaryCardEnd,
      rating: "productive"
    )
    let merged = TimelineReviewCoverageMath.mergeCoverageSegments(
      segments: [rating],
      dayStartTs: dayStart,
      dayEndTs: dayEnd
    )
    let duration = TimelineReviewCoverageMath.effectiveDuration(
      cardStart: boundaryCardStart,
      cardEnd: boundaryCardEnd,
      dayStartTs: dayStart,
      dayEndTs: dayEnd
    )
    var segmentIndex = 0
    let covered = TimelineReviewCoverageMath.overlapSeconds(
      start: boundaryCardStart,
      end: dayEnd,
      segments: merged,
      segmentIndex: &segmentIndex
    )
    XCTAssertEqual(covered, 0)
    XCTAssertLessThan(Double(covered) / Double(duration), 0.8)
  }
}
