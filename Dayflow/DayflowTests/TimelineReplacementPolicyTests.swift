import XCTest

@testable import Dayflow

final class TimelineReplacementPolicyTests: XCTestCase {
  func testOverlappingProcessingFailedCardsAreAlwaysReplaced() {
    XCTAssertTrue(
      TimelineReplacementPolicy.shouldSoftDeleteCard(
        category: "System",
        title: "Processing failed",
        cardBatchId: 1,
        replacingBatchId: 2))
    XCTAssertTrue(
      TimelineReplacementPolicy.shouldSoftDeleteCard(
        category: "Work",
        title: "Processing failed",
        cardBatchId: 9,
        replacingBatchId: 2))
  }

  func testOtherSystemCardsFromOtherBatchesArePreserved() {
    XCTAssertFalse(
      TimelineReplacementPolicy.shouldSoftDeleteCard(
        category: "System",
        title: "Idle classifier note",
        cardBatchId: 1,
        replacingBatchId: 2))
    XCTAssertTrue(
      TimelineReplacementPolicy.shouldSoftDeleteCard(
        category: "System",
        title: "Idle classifier note",
        cardBatchId: 2,
        replacingBatchId: 2))
  }

  func testNormalActivityCardsAreReplaced() {
    XCTAssertTrue(
      TimelineReplacementPolicy.shouldSoftDeleteCard(
        category: "Work",
        title: "Wrote tests",
        cardBatchId: 1,
        replacingBatchId: 2))
  }

  func testSQLPredicateMatchesFailedTitleAndBatchBind() {
    let sql = TimelineReplacementPolicy.replaceableCardsSQLPredicate
    XCTAssertTrue(sql.contains("'\(TimelineReplacementPolicy.processingFailedTitle)'"))
    XCTAssertTrue(sql.contains("category != 'System'"))
    XCTAssertTrue(sql.contains("batch_id = ?"))
  }

  func testGenerationContextDropsFailedAndSystemCards() {
    XCTAssertFalse(
      TimelineReplacementPolicy.isUsableActivityContext(
        category: "System", title: "Processing failed"))
    XCTAssertFalse(
      TimelineReplacementPolicy.isUsableActivityContext(
        category: "Work", title: "Processing failed"))
    XCTAssertTrue(
      TimelineReplacementPolicy.isUsableActivityContext(
        category: "Work", title: "Wrote tests"))
  }
}
