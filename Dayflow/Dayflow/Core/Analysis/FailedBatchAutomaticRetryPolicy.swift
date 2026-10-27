//
//  FailedBatchAutomaticRetryPolicy.swift
//  Dayflow
//
//  Shared eligibility rules for automatic failed-batch catch-up. Used by
//  AnalysisManager and timeline failure copy so scheduling and UI stay aligned.
//

import Foundation

enum FailedBatchAutomaticRetryPolicy {
  static let maxLookback: TimeInterval = 24 * 60 * 60
  static let maxAutomaticRetriesPerBatch = 3

  static func batchIdsEligibleForAutomaticRetry(
    allBatches: [(id: Int64, start: Int, end: Int, status: String)],
    retryableFailedBatchIdsOnTimeline: Set<Int64>,
    automaticRetryCounts: [Int64: Int],
    isBatchInFlight: (Int64) -> Bool,
    now: Date = Date()
  ) -> [Int64] {
    let cutoff = Int(now.timeIntervalSince1970 - maxLookback)
    let recentFailedBatches = allBatches
      .filter { $0.status == "failed" || $0.status == "processing" }
      .filter { $0.start >= cutoff && !isBatchInFlight($0.id) }
      .filter { automaticRetryCounts[$0.id, default: 0] < maxAutomaticRetriesPerBatch }
      .sorted { $0.start < $1.start }
    guard !recentFailedBatches.isEmpty else { return [] }

    return recentFailedBatches.map(\.id).filter { retryableFailedBatchIdsOnTimeline.contains($0) }
  }

  static func isBatchEligibleForAutomaticRetry(
    batchId: Int64,
    allBatches: [(id: Int64, start: Int, end: Int, status: String)],
    retryableFailedBatchIdsOnTimeline: Set<Int64>,
    automaticRetryCounts: [Int64: Int],
    isBatchInFlight: (Int64) -> Bool,
    now: Date = Date()
  ) -> Bool {
    batchIdsEligibleForAutomaticRetry(
      allBatches: allBatches,
      retryableFailedBatchIdsOnTimeline: retryableFailedBatchIdsOnTimeline,
      automaticRetryCounts: automaticRetryCounts,
      isBatchInFlight: isBatchInFlight,
      now: now
    ).contains(batchId)
  }

  static func retryableFailedBatchIdsOnTimeline(
    store: StorageManaging,
    now: Date = Date()
  ) -> Set<Int64> {
    let days = Set([
      now.getDayInfoFor4AMBoundary().dayString,
      now.addingTimeInterval(-maxLookback).getDayInfoFor4AMBoundary().dayString,
    ])
    var retryableBatchIds = Set<Int64>()
    for day in days {
      for card in store.fetchTimelineCards(forDay: day)
      where TimelineActivityLoader.isRetryableFailedCard(card, storageManager: store) {
        if let batchId = card.batchId {
          retryableBatchIds.insert(batchId)
        }
      }
    }
    return retryableBatchIds
  }
}
