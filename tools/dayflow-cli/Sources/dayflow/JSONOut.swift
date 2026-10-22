//
//  JSONOut.swift
//  dayflow-cli
//
//  Process-facing JSON printers. Envelope builders live in DayflowCLICore.
//

import Foundation
import DayflowCLICore

let schemaVersion = JSONOut.schemaVersion
let isoFormatter = JSONOut.isoFormatter

func printJSON(_ object: [String: Any]) {
  guard let text = JSONOut.encode(object) else {
    fail("could not encode response as JSON", code: 1)
  }
  print(text)
}

func failJSON(_ code: String, _ message: String, exitCode: Int32) -> Never {
  AgentUsageTelemetry.finishCLI(
    outcome: "failure",
    failureCategory: AgentUsageTelemetry.failureCategory(forExitCode: exitCode)
  )
  let error: [String: Any] = [
    "schema_version": schemaVersion,
    "error": ["code": code, "message": message],
  ]
  if let data = try? JSONSerialization.data(withJSONObject: error, options: [.sortedKeys]),
    let text = String(data: data, encoding: .utf8)
  {
    FileHandle.standardError.write(Data((text + "\n").utf8))
  }
  exit(exitCode)
}

func json(for activity: Activity, detailed: Bool) -> [String: Any] {
  JSONOut.json(for: activity, detailed: detailed)
}

func timelineEnvelope(
  _ activities: [Activity], dayKey: String, detailed: Bool
) -> [String: Any] {
  JSONOut.timelineEnvelope(activities, dayKey: dayKey, detailed: detailed)
}
