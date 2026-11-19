import XCTest

@testable import Dayflow

final class FailedBatchRetryQueueOrderingTests: XCTestCase {
  func testPriorityBatchRunsBeforeOlderFailures() {
    let ordered = FailedBatchRetryQueueOrdering.orderedBatchIds(
      chronologicalFailedBatchIds: [1, 2, 3],
      priorityBatchIds: [3]
    )

    XCTAssertEqual(ordered, [3, 1, 2])
  }

  func testMultiplePriorityBatchesKeepPriorityOrder() {
    let ordered = FailedBatchRetryQueueOrdering.orderedBatchIds(
      chronologicalFailedBatchIds: [10, 11, 12, 13],
      priorityBatchIds: [12, 10]
    )

    XCTAssertEqual(ordered, [12, 10, 11, 13])
  }

  func testEmptyPriorityPreservesChronologicalOrder() {
    let ordered = FailedBatchRetryQueueOrdering.orderedBatchIds(
      chronologicalFailedBatchIds: [5, 6],
      priorityBatchIds: []
    )

    XCTAssertEqual(ordered, [5, 6])
  }
}
