//
//  JSONOut.swift
//  dayflow-cli
//
//  Stable JSON envelopes. Keys are sorted so diffs and golden tests are
//  deterministic; every top-level object carries schema_version. This is the
//  same payload `dayflow mcp` returns as structuredContent.
//

import Foundation

public enum JSONOut {
  public static let schemaVersion = 1

  public static let isoFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
  }()

  public static func json(for activity: Activity, detailed: Bool) -> [String: Any] {
    var object: [String: Any] = [
      "record_id": activity.recordId,
      "start": isoFormatter.string(from: activity.start),
      "end": isoFormatter.string(from: activity.end),
      "duration_minutes": activity.durationMinutes,
      "title": activity.title,
      "summary": activity.summary,
      "category": activity.category,
    ]
    if !activity.subcategory.isEmpty { object["subcategory"] = activity.subcategory }
    if !activity.apps.isEmpty { object["apps"] = activity.apps }
    if activity.distractionCount > 0 { object["distraction_count"] = activity.distractionCount }
    if detailed && !activity.detailedSummary.isEmpty {
      object["detailed_summary"] = activity.detailedSummary
    }
    return object
  }

  public static func timelineEnvelope(
    _ activities: [Activity], dayKey: String, detailed: Bool
  ) -> [String: Any] {
    [
      "date": dayKey,
      "time_zone": TimeZone.current.identifier,
      "day_boundary_hour": 4,
      "cards": activities.map { json(for: $0, detailed: detailed) },
      "detail_available": !detailed,
      "hint": detailed
        ? ""
        : "Summaries are abbreviated. Use `dayflow card <record_id>` for the full write-up of a specific activity.",
    ]
  }

  public static func encode(_ object: [String: Any], prettyPrinted: Bool = true) -> String? {
    var payload = object
    payload["schema_version"] = schemaVersion
    var options: JSONSerialization.WritingOptions = [.sortedKeys]
    if prettyPrinted { options.insert(.prettyPrinted) }
    guard let data = try? JSONSerialization.data(withJSONObject: payload, options: options)
    else { return nil }
    return String(data: data, encoding: .utf8)
  }
}
