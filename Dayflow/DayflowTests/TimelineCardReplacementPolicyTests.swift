import GRDB
import XCTest

@testable import Dayflow

final class TimelineCardReplacementPolicyTests: XCTestCase {
  private var dbQueue: DatabaseQueue!

  override func setUpWithError() throws {
    dbQueue = try DatabaseQueue()
    try dbQueue.write { db in
      try db.execute(
        sql: """
          CREATE TABLE analysis_batches (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            batch_start_ts INTEGER NOT NULL,
            batch_end_ts INTEGER NOT NULL,
            status TEXT NOT NULL DEFAULT 'completed'
          );
          CREATE TABLE timeline_cards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            batch_id INTEGER,
            start TEXT NOT NULL,
            end TEXT NOT NULL,
            start_ts INTEGER,
            end_ts INTEGER,
            day TEXT NOT NULL DEFAULT '2026-01-01',
            title TEXT NOT NULL,
            category TEXT NOT NULL,
            is_deleted INTEGER NOT NULL DEFAULT 0
          );
          """)
    }
  }

  func testSequentialLookbackSupersedesEarlierBatchCard() throws {
    try insertBatch(id: 1, start: 1000, end: 1900)
    try insertBatch(id: 2, start: 1900, end: 2800)
    try insertCard(id: 1, batchId: 1, start: 1000, end: 1900, category: "Work")
    try insertCard(id: 2, batchId: 2, start: 1000, end: 2800, category: "Work")

    try retireOverlapping(from: 1000, to: 2800, batchId: 2, batchEndTs: 2800)

    XCTAssertTrue(try isDeleted(cardId: 1))
    XCTAssertFalse(try isDeleted(cardId: 2))
  }

  func testLateBatchDoesNotDeleteNewerBatchCard() throws {
    let batch809End = 23_405_3
    let batch810Start = batch809End
    try insertBatch(id: 809, start: 23_250_0, end: batch809End)
    try insertBatch(id: 810, start: batch810Start, end: 23_550_0)
    try insertCard(id: 1, batchId: 809, start: 23_250_0, end: batch809End, category: "Work")
    try insertCard(id: 2, batchId: 810, start: 23_400_0, end: 23_550_0, category: "Work")

    try retireOverlapping(from: 23_000_0, to: batch809End, batchId: 809, batchEndTs: batch809End)

    XCTAssertFalse(try isDeleted(cardId: 2))
  }

  func testIdleMergeRetiresPreviousIdleCardFromEarlierBatch() throws {
    try insertBatch(id: 10, start: 5000, end: 5900)
    try insertBatch(id: 11, start: 5900, end: 6800)
    try insertCard(id: 1, batchId: 10, start: 5000, end: 5900, category: "Idle")
    try insertCard(id: 2, batchId: 11, start: 5000, end: 6800, category: "Idle")

    try retireOverlapping(from: 5000, to: 6800, batchId: 11, batchEndTs: 6800)

    XCTAssertTrue(try isDeleted(cardId: 1))
  }

  func testClipInsertTimestampsBeforePreservedNewerBatchCard() {
    let preserved = [(startTs: 23_400_0, endTs: 23_550_0)]
    let clipped = TimelineCardReplacementPolicy.clipInsertTimestamps(
      startTs: 23_250_0, endTs: 23_405_3, preserved: preserved)
    XCTAssertEqual(clipped?.endTs, 23_400_0)
  }

  func testClipInsertTimestampsSkipsWhenFullyOwnedByNewerBatch() {
    let preserved = [(startTs: 23_400_0, endTs: 23_550_0)]
    XCTAssertNil(
      TimelineCardReplacementPolicy.clipInsertTimestamps(
        startTs: 23_410_0, endTs: 23_500_0, preserved: preserved))
  }

  func testPreservesSystemCardFromAnotherBatch() throws {
    try insertBatch(id: 1, start: 1000, end: 2000)
    try insertBatch(id: 2, start: 2000, end: 3000)
    try insertCard(id: 1, batchId: 1, start: 1000, end: 2000, category: "System")
    try insertCard(id: 2, batchId: 2, start: 1000, end: 3000, category: "Work")

    try retireOverlapping(from: 1000, to: 3000, batchId: 2, batchEndTs: 3000)

    XCTAssertFalse(try isDeleted(cardId: 1))
    XCTAssertTrue(try isDeleted(cardId: 2))
  }

  // MARK: - Helpers

  private func insertBatch(id: Int64, start: Int, end: Int) throws {
    try dbQueue.write { db in
      try db.execute(
        sql: """
          INSERT INTO analysis_batches (id, batch_start_ts, batch_end_ts)
          VALUES (?, ?, ?)
          """, arguments: [id, start, end])
    }
  }

  private func insertCard(
    id: Int64, batchId: Int64, start: Int, end: Int, category: String
  ) throws {
    try dbQueue.write { db in
      try db.execute(
        sql: """
          INSERT INTO timeline_cards
            (id, batch_id, start, end, start_ts, end_ts, title, category)
          VALUES (?, ?, 's', 'e', ?, ?, 't', ?)
          """, arguments: [id, batchId, start, end, category])
    }
  }

  private func retireOverlapping(from fromTs: Int, to toTs: Int, batchId: Int64, batchEndTs: Int)
    throws
  {
    try dbQueue.write { db in
      try db.execute(
        sql: """
          UPDATE timeline_cards
          SET is_deleted = 1
          WHERE \(TimelineCardReplacementPolicy.timeRangeOverlapSQL)
             AND \(TimelineCardReplacementPolicy.retirementPredicateSQL)
          """, arguments: [toTs, fromTs, fromTs, toTs, batchId, batchEndTs])
    }
  }

  private func isDeleted(cardId: Int64) throws -> Bool {
    try dbQueue.read { db in
      try Int.fetchOne(
        db, sql: "SELECT is_deleted FROM timeline_cards WHERE id = ?", arguments: [cardId]
      ) == 1
    }
  }
}
