//
//  Queries.swift
//  dayflow-cli
//
//  Typed reads over Dayflow's schema. SQL semantics deliberately mirror
//  StorageManager: day queries select cards *starting* inside the 4 AM window,
//  range queries select cards overlapping the window, both skip soft-deleted
//  rows, both order by start_ts.
//

import Foundation

public struct Activity {
  public let recordId: Int
  public let start: Date
  public let end: Date
  public let title: String
  public let summary: String
  public let detailedSummary: String
  public let category: String
  public let subcategory: String
  public let apps: [String]
  public let distractionCount: Int

  public var durationMinutes: Int { max(0, Int(end.timeIntervalSince(start)) / 60) }

  public init(
    recordId: Int,
    start: Date,
    end: Date,
    title: String,
    summary: String,
    detailedSummary: String,
    category: String,
    subcategory: String,
    apps: [String],
    distractionCount: Int
  ) {
    self.recordId = recordId
    self.start = start
    self.end = end
    self.title = title
    self.summary = summary
    self.detailedSummary = detailedSummary
    self.category = category
    self.subcategory = subcategory
    self.apps = apps
    self.distractionCount = distractionCount
  }
}

public struct StandupDocument {
  public let day: String
  public let highlightsTitle: String
  public let highlights: [String]
  public let tasksTitle: String
  public let tasks: [String]
  public let blockersTitle: String
  public let blockersBody: String
}

// The subset of timeline_cards.metadata this tool reads. The app's full
// TimelineMetadata has more fields (idle classifier data, backup flags);
// unknown keys are ignored by design.
private struct CardMetadata: Decodable {
  struct AppSites: Decodable {
    let primary: String?
    let secondary: String?
  }
  struct Distraction: Decodable {
    let title: String?
  }
  let appSites: AppSites?
  let distractions: [Distraction]?
}

private func activity(from row: SQLRow) -> Activity? {
  guard let recordId = row.int("id"),
    let startTs = row.int("start_ts"),
    let endTs = row.int("end_ts")
  else { return nil }

  var apps: [String] = []
  var distractionCount = 0
  if let metadataString = row.string("metadata"),
    let data = metadataString.data(using: .utf8),
    let metadata = try? JSONDecoder().decode(CardMetadata.self, from: data)
  {
    if let primary = metadata.appSites?.primary { apps.append(primary) }
    if let secondary = metadata.appSites?.secondary { apps.append(secondary) }
    distractionCount = metadata.distractions?.count ?? 0
  }

  return Activity(
    recordId: recordId,
    start: Date(timeIntervalSince1970: TimeInterval(startTs)),
    end: Date(timeIntervalSince1970: TimeInterval(endTs)),
    title: row.string("title") ?? "",
    summary: row.string("summary") ?? "",
    detailedSummary: row.string("detailed_summary") ?? "",
    category: row.string("category") ?? "",
    subcategory: row.string("subcategory") ?? "",
    apps: apps,
    distractionCount: distractionCount
  )
}

private let cardColumns = """
  id, start_ts, end_ts, title, summary, detailed_summary,
  category, subcategory, metadata
  """

public func fetchActivities(db: Database, window: DayWindow) throws -> [Activity] {
  try db.query(
    """
    SELECT \(cardColumns) FROM timeline_cards
    WHERE start_ts >= ? AND start_ts < ? AND is_deleted = 0
    ORDER BY start_ts ASC
    """,
    [
      .integer(Int64(window.start.timeIntervalSince1970)),
      .integer(Int64(window.end.timeIntervalSince1970)),
    ]
  ).compactMap(activity(from:))
}

public func fetchActivities(db: Database, from: Date, to: Date) throws -> [Activity] {
  try db.query(
    """
    SELECT \(cardColumns) FROM timeline_cards
    WHERE start_ts < ? AND end_ts > ? AND is_deleted = 0
    ORDER BY start_ts ASC
    """,
    [
      .integer(Int64(to.timeIntervalSince1970)),
      .integer(Int64(from.timeIntervalSince1970)),
    ]
  ).compactMap(activity(from:))
}

public func fetchActivity(db: Database, recordId: Int) throws -> Activity? {
  try db.query(
    "SELECT \(cardColumns) FROM timeline_cards WHERE id = ? AND is_deleted = 0",
    [.integer(Int64(recordId))]
  ).compactMap(activity(from:)).first
}

public func searchActivities(db: Database, text: String, limit: Int = 50) throws -> [Activity] {
  let pattern = "%\(text)%"
  return try db.query(
    """
    SELECT \(cardColumns) FROM timeline_cards
    WHERE (title LIKE ? OR summary LIKE ?) AND is_deleted = 0
    ORDER BY start_ts DESC
    LIMIT ?
    """,
    [.text(pattern), .text(pattern), .integer(Int64(limit))]
  ).compactMap(activity(from:))
}

public func fetchStandup(db: Database, day: String) throws -> StandupDocument? {
  guard
    let payload = try db.query(
      "SELECT payload_json FROM daily_standup_entries WHERE standup_day = ?",
      [.text(day)]
    ).first?.string("payload_json"),
    let data = payload.data(using: .utf8)
  else { return nil }

  struct Item: Decodable { let text: String }
  struct Payload: Decodable {
    let highlightsTitle: String?
    let highlights: [Item]?
    let tasksTitle: String?
    let tasks: [Item]?
    let blockersTitle: String?
    let blockersBody: String?
  }

  guard let decoded = try? JSONDecoder().decode(Payload.self, from: data) else { return nil }
  return StandupDocument(
    day: day,
    highlightsTitle: decoded.highlightsTitle ?? "Highlights",
    highlights: (decoded.highlights ?? []).map(\.text),
    tasksTitle: decoded.tasksTitle ?? "Tasks",
    tasks: (decoded.tasks ?? []).map(\.text),
    blockersTitle: decoded.blockersTitle ?? "Blockers",
    blockersBody: decoded.blockersBody ?? ""
  )
}

public struct StatusInfo {
  public let databasePath: String
  public let lastCaptureAt: Date?
  public let pendingBatches: Int
  public let failedBatches: Int
  public let today: String
}

public func fetchStatus(db: Database, path: String) throws -> StatusInfo {
  let lastCapture = try db.query(
    "SELECT max(captured_at) AS ts FROM screenshots WHERE is_deleted = 0"
  ).first?.int("ts")

  let counts = try db.query(
    """
    SELECT
      sum(CASE WHEN status IN ('pending', 'processing') THEN 1 ELSE 0 END) AS pending,
      sum(CASE WHEN status LIKE 'failed%' THEN 1 ELSE 0 END) AS failed
    FROM analysis_batches
    """
  ).first

  return StatusInfo(
    databasePath: path,
    lastCaptureAt: lastCapture.map { Date(timeIntervalSince1970: TimeInterval($0)) },
    pendingBatches: counts?.int("pending") ?? 0,
    failedBatches: counts?.int("failed") ?? 0,
    today: dayWindow(containing: Date()).dayKey
  )
}
