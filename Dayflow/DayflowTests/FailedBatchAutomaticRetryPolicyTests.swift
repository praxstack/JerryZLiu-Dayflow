import XCTest

@testable import Dayflow

final class FailedBatchAutomaticRetryPolicyTests: XCTestCase {
  private let now = Date(timeIntervalSince1970: 1_700_000_000)

  func testEligibleBatchWithinLookbackAndRetryBudget() {
    let start = Int(now.timeIntervalSince1970 - 3600)
    let batches = [(id: Int64(1), start: start, end: start + 900, status: "failed")]

    let eligible = FailedBatchAutomaticRetryPolicy.batchIdsEligibleForAutomaticRetry(
      allBatches: batches,
      retryableFailedBatchIdsOnTimeline: [1],
      automaticRetryCounts: [:],
      isBatchInFlight: { _ in false },
      now: now
    )

    XCTAssertEqual(eligible, [1])
  }

  func testBatchOlderThanLookbackIsNotEligible() {
    let start = Int(now.timeIntervalSince1970 - FailedBatchAutomaticRetryPolicy.maxLookback - 60)
    let batches = [(id: Int64(2), start: start, end: start + 900, status: "failed")]

    let eligible = FailedBatchAutomaticRetryPolicy.batchIdsEligibleForAutomaticRetry(
      allBatches: batches,
      retryableFailedBatchIdsOnTimeline: [2],
      automaticRetryCounts: [:],
      isBatchInFlight: { _ in false },
      now: now
    )

    XCTAssertTrue(eligible.isEmpty)
  }

  func testBatchAtAutomaticRetryLimitIsNotEligible() {
    let start = Int(now.timeIntervalSince1970 - 3600)
    let batches = [(id: Int64(3), start: start, end: start + 900, status: "failed")]

    let eligible = FailedBatchAutomaticRetryPolicy.batchIdsEligibleForAutomaticRetry(
      allBatches: batches,
      retryableFailedBatchIdsOnTimeline: [3],
      automaticRetryCounts: [3: FailedBatchAutomaticRetryPolicy.maxAutomaticRetriesPerBatch],
      isBatchInFlight: { _ in false },
      now: now
    )

    XCTAssertTrue(eligible.isEmpty)
  }

  func testBatchWithoutRetryableFailedCardOnTimelineIsNotEligible() {
    let start = Int(now.timeIntervalSince1970 - 3600)
    let batches = [(id: Int64(4), start: start, end: start + 900, status: "failed")]

    let eligible = FailedBatchAutomaticRetryPolicy.batchIdsEligibleForAutomaticRetry(
      allBatches: batches,
      retryableFailedBatchIdsOnTimeline: [],
      automaticRetryCounts: [:],
      isBatchInFlight: { _ in false },
      now: now
    )

    XCTAssertTrue(eligible.isEmpty)
  }
}
