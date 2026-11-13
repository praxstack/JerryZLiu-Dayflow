//
//  FailedBatchRetryQueueOrdering.swift
//  Dayflow
//
//  Orders failed batches for manual retry: clicked batch(es) first, then the rest
//  of the day's queue in chronological order.
//

import Foundation

enum FailedBatchRetryQueueOrdering {
  static func orderedBatchIds(
    chronologicalFailedBatchIds: [Int64],
    priorityBatchIds: [Int64]
  ) -> [Int64] {
    guard !priorityBatchIds.isEmpty else { return chronologicalFailedBatchIds }

    var seen = Set<Int64>()
    var ordered: [Int64] = []

    for batchId in priorityBatchIds where chronologicalFailedBatchIds.contains(batchId) {
      guard seen.insert(batchId).inserted else { continue }
      ordered.append(batchId)
    }

    for batchId in chronologicalFailedBatchIds where seen.insert(batchId).inserted {
      ordered.append(batchId)
    }

    return ordered
  }
}
