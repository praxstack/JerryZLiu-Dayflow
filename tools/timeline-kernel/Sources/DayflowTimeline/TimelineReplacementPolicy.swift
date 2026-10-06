//
//  TimelineReplacementPolicy.swift
//  Dayflow
//
//  Pure policy for sliding-window card replacement (JerryZLiu/Dayflow#285).
//  Processing-failed cards used to be preserved whenever they belonged to
//  another batch, so overlapping failures stacked into tens of thousands of
//  System cards. Failed cards in the replacement window are always replaced.
//

import Foundation

enum TimelineReplacementPolicy {
  static let processingFailedTitle = "Processing failed"

  /// SQL WHERE fragment matching `shouldSoftDeleteCard`. Bind replacingBatchId last.
  static var replaceableCardsSQLPredicate: String {
    "(title = '\(processingFailedTitle)' OR category != 'System' OR batch_id = ?)"
  }

  /// Soft-delete extra live Processing failed cards, keeping the lowest id
  /// per (day, start_ts, end_ts). Cleans historical stacks from #285.
  static var historicalDuplicateFailedCardsSQL: String {
    """
    UPDATE timeline_cards
    SET is_deleted = 1
    WHERE is_deleted = 0
      AND title = '\(processingFailedTitle)'
      AND id NOT IN (
        SELECT keep_id FROM (
          SELECT MIN(id) AS keep_id FROM timeline_cards
          WHERE is_deleted = 0 AND title = '\(processingFailedTitle)'
          GROUP BY day, COALESCE(start_ts, 0), COALESCE(end_ts, 0)
        )
      )
    """
  }

  struct StoredCardRef: Equatable {
    var id: Int64
    var day: String
    var startTs: Int?
    var endTs: Int?
    var title: String
    var isDeleted: Bool
  }

  /// Ids of live Processing failed duplicates to soft-delete. Keeps MIN(id)
  /// per window so a single error card can remain as a marker.
  static func historicalDuplicateFailedIds(in cards: [StoredCardRef]) -> [Int64] {
    var kept: [String: Int64] = [:]
    var toDelete: [Int64] = []
    let liveFailed = cards
      .filter { !$0.isDeleted && $0.title == processingFailedTitle }
      .sorted { $0.id < $1.id }
    for card in liveFailed {
      let key = "\(card.day)|\(card.startTs ?? 0)|\(card.endTs ?? 0)"
      if kept[key] == nil {
        kept[key] = card.id
      } else {
        toDelete.append(card.id)
      }
    }
    return toDelete
  }

  /// Whether `replaceTimelineCardsInRange` should soft-delete this live card.
  static func shouldSoftDeleteCard(
    category: String,
    title: String,
    cardBatchId: Int64?,
    replacingBatchId: Int64
  ) -> Bool {
    if title == processingFailedTitle { return true }
    if category != "System" { return true }
    return cardBatchId == replacingBatchId
  }

  /// Cards the model should see as prior context. System / processing-failed
  /// rows are storage bookkeeping, not activities.
  static func isUsableActivityContext(category: String, title: String) -> Bool {
    category != "System" && title != processingFailedTitle
  }
}
