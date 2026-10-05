import Foundation
import XCTest
import DayflowCLICore

final class JSONOutTests: XCTestCase {
  func testTimelineEnvelopeHasStableMCPKeys() throws {
    let start = Date(timeIntervalSince1970: 1_773_205_200)
    let end = Date(timeIntervalSince1970: 1_773_210_600)
    let activity = Activity(
      recordId: 42,
      start: start,
      end: end,
      title: "Ship CLI tests",
      summary: "Cover JSON envelopes.",
      detailedSummary: "Full write-up of the JSON envelope work.",
      category: "Work",
      subcategory: "Engineering",
      apps: ["Cursor"],
      distractionCount: 1
    )

    let envelope = JSONOut.timelineEnvelope([activity], dayKey: "2026-03-11", detailed: false)
    XCTAssertEqual(envelope["date"] as? String, "2026-03-11")
    XCTAssertEqual(envelope["day_boundary_hour"] as? Int, 4)
    XCTAssertEqual(envelope["time_zone"] as? String, TimeZone.current.identifier)
    XCTAssertEqual(envelope["detail_available"] as? Bool, true)
    XCTAssertTrue((envelope["hint"] as? String)?.contains("dayflow card") == true)

    let cards = try XCTUnwrap(envelope["cards"] as? [[String: Any]])
    XCTAssertEqual(cards.count, 1)
    XCTAssertEqual(cards[0]["record_id"] as? Int, 42)
    XCTAssertEqual(cards[0]["title"] as? String, "Ship CLI tests")
    XCTAssertEqual(cards[0]["category"] as? String, "Work")
    XCTAssertEqual(cards[0]["subcategory"] as? String, "Engineering")
    XCTAssertEqual(cards[0]["apps"] as? [String], ["Cursor"])
    XCTAssertEqual(cards[0]["distraction_count"] as? Int, 1)
    XCTAssertNil(cards[0]["detailed_summary"])

    let encoded = try XCTUnwrap(JSONOut.encode(envelope))
    XCTAssertTrue(encoded.contains("schema_version"))
    XCTAssertTrue(encoded.contains("day_boundary_hour"))
  }

  func testDetailedCardIncludesWriteUp() {
    let activity = Activity(
      recordId: 7,
      start: Date(timeIntervalSince1970: 0),
      end: Date(timeIntervalSince1970: 600),
      title: "Review",
      summary: "Short",
      detailedSummary: "The long write-up.",
      category: "Work",
      subcategory: "",
      apps: [],
      distractionCount: 0
    )
    let object = JSONOut.json(for: activity, detailed: true)
    XCTAssertEqual(object["detailed_summary"] as? String, "The long write-up.")
    XCTAssertEqual(object["duration_minutes"] as? Int, 10)
    XCTAssertNil(object["subcategory"])
    XCTAssertNil(object["apps"])
    XCTAssertNil(object["distraction_count"])
  }
}

final class QueriesTests: XCTestCase {
  func testFetchActivitiesReturnsFixtureCardsInDayWindow() throws {
    let dbPath = try makeFixture()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }
    let db = try Database(path: dbPath)

    let all = try fetchActivities(
      db: db,
      from: Date(timeIntervalSince1970: 0),
      to: Date(timeIntervalSince1970: 2_000_000_000)
    )
    XCTAssertEqual(all.count, 2)
    XCTAssertEqual(
      Set(all.map(\.title)),
      [
        "Ship Dayflow CLI timeline command",
        "Review pull request",
      ])
    XCTAssertEqual(all[0].apps, ["Cursor", "Terminal"])
    XCTAssertEqual(all[1].distractionCount, 1)

    let window = dayWindow(containing: all[0].start)
    let dayCards = try fetchActivities(db: db, window: window)
    XCTAssertTrue(dayCards.contains(where: { $0.recordId == all[0].recordId }))
  }

  func testSearchAndSingleCard() throws {
    let dbPath = try makeFixture()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }
    let db = try Database(path: dbPath)
    let matches = try searchActivities(db: db, text: "CLI")
    XCTAssertEqual(matches.count, 1)
    XCTAssertEqual(matches[0].title, "Ship Dayflow CLI timeline command")
    let card = try fetchActivity(db: db, recordId: matches[0].recordId)
    XCTAssertEqual(card?.detailedSummary.contains("SQL query parity"), true)
  }

  func testSoftDeletedRowsAreSkipped() throws {
    let dbPath = try makeFixture()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }
    try runSQL(dbPath, "UPDATE timeline_cards SET is_deleted = 1 WHERE title LIKE '%CLI%'")
    let db = try Database(path: dbPath)
    let all = try fetchActivities(
      db: db,
      from: Date(timeIntervalSince1970: 0),
      to: Date(timeIntervalSince1970: 2_000_000_000)
    )
    XCTAssertEqual(all.map(\.title), ["Review pull request"])
  }

  func testFetchStandup() throws {
    let dbPath = try makeFixture()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }
    let db = try Database(path: dbPath)
    let standup = try fetchStandup(db: db, day: "2026-03-11")
    XCTAssertEqual(standup?.highlights, ["Dayflow CLI builds on Linux"])
    XCTAssertNil(try fetchStandup(db: db, day: "1999-01-01"))
  }

  private func makeFixture() throws -> String {
    let path = FileManager.default.temporaryDirectory
      .appendingPathComponent("dayflow-queries-\(UUID().uuidString).sqlite").path
    let script = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("fixtures/create_fixture_db.sh")
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/bash")
    process.arguments = [script.path, path]
    try process.run()
    process.waitUntilExit()
    XCTAssertEqual(process.terminationStatus, 0, "fixture script failed")
    return path
  }

  private func runSQL(_ dbPath: String, _ sql: String) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["sqlite3", dbPath, sql]
    try process.run()
    process.waitUntilExit()
    XCTAssertEqual(process.terminationStatus, 0)
  }
}
