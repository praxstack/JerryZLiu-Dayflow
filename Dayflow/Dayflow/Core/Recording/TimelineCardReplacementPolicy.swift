import Foundation
import GRDB

/// Which existing timeline cards may be soft-deleted when a batch replaces cards in a time range.
enum TimelineCardReplacementPolicy {
  /// Shared overlap filter for `replaceTimelineCardsInRange` queries.
  static let timeRangeOverlapSQL = """
    ((start_ts < ? AND end_ts > ?)
       OR (start_ts >= ? AND start_ts < ?))
      AND is_deleted = 0
    """

  /// Retire this batch's rows, supersede older non-System cards, and keep cards from
  /// batches that start at or after this batch's end (late completion must not wipe N+1).
  static let retirementPredicateSQL = """
    (batch_id = ?
     OR (category != 'System'
         AND (batch_id IS NULL
              OR batch_id NOT IN (SELECT id FROM analysis_batches
                                  WHERE batch_start_ts >= ?))))
    """

  static func batchEndTimestamp(db: Database, batchId: Int64, fallbackToTs: Int) throws -> Int {
    try Int.fetchOne(
      db,
      sql: "SELECT batch_end_ts FROM analysis_batches WHERE id = ?",
      arguments: [batchId]
    ) ?? fallbackToTs
  }

  /// Active non-System cards owned by batches that start at or after this batch's end.
  static let preservedNewerBatchOverlapSQL = """
    batch_id IN (SELECT id FROM analysis_batches WHERE batch_start_ts >= ?)
      AND category != 'System'
      AND \(timeRangeOverlapSQL)
    """

  /// Returns clipped `(startTs, endTs)` or `nil` when a preserved newer card fully owns the interval.
  static func clipInsertTimestamps(
    startTs: Int, endTs: Int, preserved: [(startTs: Int, endTs: Int)]
  ) -> (startTs: Int, endTs: Int)? {
    var s = startTs
    var e = endTs
    for block in preserved {
      if block.endTs <= s || block.startTs >= e { continue }
      if block.startTs <= s && block.endTs >= e { return nil }
      if block.startTs > s && block.startTs < e { e = block.startTs }
      if block.endTs > s && block.endTs < e && block.startTs <= s { s = block.endTs }
    }
    return e > s ? (s, e) : nil
  }
}
