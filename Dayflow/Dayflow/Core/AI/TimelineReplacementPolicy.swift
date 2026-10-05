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
