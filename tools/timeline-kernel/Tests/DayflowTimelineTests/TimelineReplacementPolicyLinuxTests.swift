import XCTest
@testable import DayflowTimeline

final class TimelineReplacementPolicyLinuxTests: XCTestCase {
  func testHistoricalCleanupKeepsOneFailedCardPerWindow() {
    let cards: [TimelineReplacementPolicy.StoredCardRef] = [
      .init(
        id: 10, day: "2026-06-16", startTs: 100, endTs: 200, title: "Processing failed",
        isDeleted: false),
      .init(
        id: 11, day: "2026-06-16", startTs: 100, endTs: 200, title: "Processing failed",
        isDeleted: false),
      .init(
        id: 12, day: "2026-06-16", startTs: 200, endTs: 300, title: "Processing failed",
        isDeleted: false),
      .init(
        id: 13, day: "2026-06-16", startTs: 100, endTs: 200, title: "Wrote tests", isDeleted: false),
    ]
    XCTAssertEqual(
      TimelineReplacementPolicy.historicalDuplicateFailedIds(in: cards),
      [11])
  }

  func testOverlappingFailedCardsStillAlwaysReplaced() {
    XCTAssertTrue(
      TimelineReplacementPolicy.shouldSoftDeleteCard(
        category: "System",
        title: "Processing failed",
        cardBatchId: 1,
        replacingBatchId: 2))
  }

  func testCleanupSQLIsIdempotentSoftDelete() {
    let sql = TimelineReplacementPolicy.historicalDuplicateFailedCardsSQL
    XCTAssertTrue(sql.contains("SET is_deleted = 1"))
    XCTAssertFalse(sql.contains("DELETE FROM"))
  }
}
