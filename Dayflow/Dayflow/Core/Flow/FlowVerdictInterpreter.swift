//
//  FlowVerdictInterpreter.swift
//  Dayflow
//
//  Pure parsing of Flow distraction-agent model replies. Unparseable
//  output is treated as on-task / no overlay action.
//

import Foundation

enum FlowVerdictInterpreter {
  struct Verdict: Decodable, Equatable {
    var status: String?
    var action: String?
    var message: String?
    var reason: String?
    var completed_goals: [String]?
  }

  /// Every top-level `{...}` in the reply, in order, tolerating fences and
  /// stray prose. Strings are skipped so braces inside a title don't confuse
  /// the depth count.
  static func jsonObjects(in reply: String) -> [String] {
    var objects: [String] = []
    var depth = 0
    var start: String.Index?
    var inString = false
    var escaped = false
    var index = reply.startIndex
    while index < reply.endIndex {
      let character = reply[index]
      if inString {
        if escaped {
          escaped = false
        } else if character == "\\" {
          escaped = true
        } else if character == "\"" {
          inString = false
        }
      } else if character == "\"" {
        inString = true
      } else if character == "{" {
        if depth == 0 { start = index }
        depth += 1
      } else if character == "}" {
        depth -= 1
        if depth == 0, let begin = start {
          objects.append(String(reply[begin...index]))
          start = nil
        }
        if depth < 0 { depth = 0 }
      }
      index = reply.index(after: index)
    }
    return objects
  }

  /// First JSON object decoded as a verdict, or nil if nothing usable.
  static func parse(_ reply: String) -> Verdict? {
    guard let first = jsonObjects(in: reply).first else { return nil }
    return try? JSONDecoder().decode(Verdict.self, from: Data(first.utf8))
  }
}
