//
//  FlowVerdictInterpreter.swift
//  Dayflow
//
//  Pure parsing of Flow distraction-agent model replies, plus the overlay
//  presentation implied by a verdict or session phase change. Unparseable
//  output is treated as on-task / no overlay action so a flaky turn can
//  never fire a bogus nudge.
//
//  Compiled into the macOS app via the DayflowFlow PBXFileSystemSynchronizedRootGroup
//  in Dayflow.xcodeproj (tools/flow-kernel/Sources/DayflowFlow) and into
//  Linux/SwiftPM tests via this package.
//

import Foundation

public enum FlowAgentDecision: Equatable {
  case onTask
  case offTask(message: String?)
  case nudge(message: String)
  case praise(message: String)
}

public enum FlowOverlayAction: Equatable {
  case none
  case nudge(String)
  case praise(String)
}

public struct FlowParsedVerdict: Equatable {
  public var decision: FlowAgentDecision
  public var isOffTask: Bool
  public var overlay: FlowOverlayAction
  public var message: String?
  public var reason: String?
  public var completedGoals: [String]

  public static let onTask = FlowParsedVerdict(
    decision: .onTask,
    isOffTask: false,
    overlay: .none,
    message: nil,
    reason: nil,
    completedGoals: []
  )
}

public enum FlowVerdictInterpreter {
  public struct Verdict: Decodable, Equatable {
    public var status: String?
    public var action: String?
    public var message: String?
    public var reason: String?
    public var completed_goals: [String]?
  }

  /// Every top-level `{...}` in the reply, in order, tolerating fences and
  /// stray prose. Strings are skipped so braces inside a title don't confuse
  /// the depth count.
  public static func jsonObjects(in reply: String) -> [String] {
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
  /// The agent uses this to distinguish garbage (no handle / no focus flip)
  /// from a decoded on-task default.
  public static func decode(_ reply: String) -> Verdict? {
    guard let first = jsonObjects(in: reply).first else { return nil }
    return try? JSONDecoder().decode(Verdict.self, from: Data(first.utf8))
  }

  /// Fail-safe parse: garbage, empty objects, and missing fields are on-task.
  public static func parse(_ string: String) -> FlowAgentDecision {
    parseDetails(string).decision
  }

  public static func parse(_ data: Data) -> FlowAgentDecision {
    parse(String(decoding: data, as: UTF8.self))
  }

  /// Full verdict used by FlowDistractionAgent. Status and overlay action stay
  /// independent (a nudge can accompany either on-task or off-task).
  public static func parseDetails(_ reply: String) -> FlowParsedVerdict {
    guard let verdict = decode(reply) else { return .onTask }
    return interpret(verdict)
  }

  public static func interpret(_ verdict: Verdict) -> FlowParsedVerdict {
    let isOffTask = verdict.status == "off_task"
    let overlay: FlowOverlayAction
    switch verdict.action {
    case "nudge":
      overlay = .nudge(verdict.message ?? "")
    case "praise":
      if let message = verdict.message, !message.isEmpty {
        overlay = .praise(message)
      } else {
        overlay = .none
      }
    default:
      overlay = .none
    }

    let decision: FlowAgentDecision
    switch overlay {
    case .nudge(let message):
      decision = .nudge(message: message)
    case .praise(let message):
      decision = .praise(message: message)
    case .none:
      if isOffTask {
        decision = .offTask(message: verdict.message)
      } else {
        decision = .onTask
      }
    }

    return FlowParsedVerdict(
      decision: decision,
      isOffTask: isOffTask,
      overlay: overlay,
      message: verdict.message,
      reason: verdict.reason,
      completedGoals: verdict.completed_goals ?? []
    )
  }
}

/// Overlay presentation implied by session phase changes or agent actions.
/// FlowSessionMirror still owns timers and AppKit; this is the testable policy.
public enum FlowOverlayMapping {
  public static func event(from previous: FlowPhase, to new: FlowPhase) -> FlowPhaseOverlayEvent {
    switch new {
    case .active:
      switch previous {
      case .idle, .ended:
        return .sessionStarted
      case .onBreak:
        return .breakOver
      case .active:
        return .unchanged
      }
    case .onBreak:
      return .onBreak
    case .idle:
      return .hide
    case .ended:
      // apply() does not show sessionEnded; the deadline timer does.
      return .unchanged
    }
  }

  public static let defaultNudgeMessage = "Psst... I think you're getting distracted!"

  public static func overlay(
    for action: FlowOverlayAction,
    phase: FlowPhase,
    alertStyle: FlowAlertStyle,
    snoozed: Bool,
    current: FlowOverlayPresentation,
    nudgeStreakAfterThisNudge: Int
  ) -> FlowOverlayPresentation? {
    guard phase == .active, alertStyle != .quiet else { return nil }
    switch action {
    case .none:
      return nil
    case .nudge(let message):
      if snoozed { return nil }
      let text = message.isEmpty ? defaultNudgeMessage : message
      return .nudge(message: text, escalated: nudgeStreakAfterThisNudge >= 2)
    case .praise(let message):
      if case .nudge = current { return nil }
      return .toast(message: message)
    }
  }
}
