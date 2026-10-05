//
//  FlowNativeState.swift
//  Dayflow
//
//  Thin native mirror of Flow session state. The backend (via the hosted web
//  UI) owns the real data; the app only keeps enough to drive the desktop
//  overlay and survive a relaunch mid-session.
//
//  Compiled into the macOS app via
//  `Dayflow/Dayflow/Core/Flow/FlowNativeState.swift` (symlink into this file)
//  and into Linux/SwiftPM tests via tools/flow-kernel.
//

import Foundation

public enum FlowAlertStyle: String, Codable, CaseIterable {
  case quiet
  case friendly
  case feisty
}

public enum FlowPhase: String, Codable {
  case idle
  case active
  case onBreak = "break"
  case ended
}

/// An open task the user wants done this session, with the id the web app
/// needs to check it off when the agent sees it finished.
public struct FlowGoalTask: Codable, Equatable {
  public var id: String
  public var title: String

  public init(id: String, title: String) {
    self.id = id
    self.title = title
  }
}

/// Snapshot the web UI pushes over the bridge whenever session state changes.
/// Timestamps are unix seconds so the overlay can count down locally without
/// chatty bridge traffic.
public struct FlowNativeSnapshot: Codable, Equatable {
  public var phase: FlowPhase = .idle
  public var alertStyle: FlowAlertStyle = .friendly
  /// nil when idle or when the session is "always on".
  public var sessionEndsAt: Int?
  public var breakEndsAt: Int?
  public var alwaysOn: Bool = false
  /// When the active session began (unix seconds); nil when idle.
  public var sessionStartedAt: Int?
  /// The user's stated focus for the session (priority task titles).
  public var goals: [String]?
  /// The same tasks with ids, for the agent's goal tracking.
  public var goalTasks: [FlowGoalTask]?

  public static let idle = FlowNativeSnapshot()

  private static let defaultsKey = "flowNativeSnapshot"

  public static func loadPersisted(defaults: UserDefaults = .standard) -> FlowNativeSnapshot {
    guard let data = defaults.data(forKey: defaultsKey),
      let snapshot = try? JSONDecoder().decode(FlowNativeSnapshot.self, from: data)
    else { return .idle }
    return snapshot
  }

  public func persist(defaults: UserDefaults = .standard) {
    guard let data = try? JSONEncoder().encode(self) else { return }
    defaults.set(data, forKey: Self.defaultsKey)
  }

  public init() {}

  public init?(bridgePayload payload: [String: Any]) {
    guard let phaseRaw = payload["phase"] as? String,
      let phase = FlowPhase(rawValue: phaseRaw)
    else { return nil }
    self.phase = phase
    self.alertStyle =
      (payload["alertStyle"] as? String).flatMap(FlowAlertStyle.init(rawValue:)) ?? .friendly
    self.sessionEndsAt = payload["sessionEndsAt"] as? Int
    self.breakEndsAt = payload["breakEndsAt"] as? Int
    self.alwaysOn = payload["alwaysOn"] as? Bool ?? false
    self.sessionStartedAt = payload["sessionStartedAt"] as? Int
    self.goals = payload["goals"] as? [String]
    self.goalTasks = (payload["goalTasks"] as? [[String: Any]])?.compactMap { entry in
      guard let id = entry["id"] as? String, let title = entry["title"] as? String else {
        return nil
      }
      return FlowGoalTask(id: id, title: title)
    }
  }

  public var bridgePayload: [String: Any] {
    var payload: [String: Any] = [
      "phase": phase.rawValue,
      "alertStyle": alertStyle.rawValue,
      "alwaysOn": alwaysOn,
    ]
    if let sessionEndsAt { payload["sessionEndsAt"] = sessionEndsAt }
    if let breakEndsAt { payload["breakEndsAt"] = breakEndsAt }
    if let sessionStartedAt { payload["sessionStartedAt"] = sessionStartedAt }
    if let goals { payload["goals"] = goals }
    if let goalTasks { payload["goalTasks"] = goalTasks.map { ["id": $0.id, "title": $0.title] } }
    return payload
  }
}

/// What the overlay panel is currently showing.
public enum FlowOverlayPresentation: Equatable {
  case hidden
  /// Short auto-dismissing speech bubble ("Your flow session starts now!").
  case toast(message: String)
  /// Distraction nudge with quick-reply pills. `escalated` marks a repeat
  /// nudge in the same incident — the creature loses its temper (fire clips)
  /// instead of waving. The message is written by the
  /// detection agent (or a stock line for the ⌘⇧D simulation).
  case nudge(message: String, escalated: Bool)
  /// Break in progress: tub + countdown driven by `breakEndsAt`.
  case onBreak
  /// Timed session hit its natural end.
  case sessionEnded
}

/// Overlay implied by a session phase change. Strings stay in FlowSessionMirror
/// so they can go through `String(localized:)`; this is the testable policy.
public enum FlowPhaseOverlayEvent: Equatable {
  case sessionStarted
  case onBreak
  case breakOver
  case hide
  case unchanged
}

/// Where the nudge creature comes from. `side` is the Figma layout (peeks in
/// at the bottom-right corner); `top` drops down from the top edge, lands and
/// listens; `peek` hangs half-body from the top edge. Chosen from the app
/// menu while we experiment; toasts and breaks always use the side layout.
public enum FlowNudgeVariant: String, CaseIterable {
  case side
  case top
  case peek

  public static let defaultsKey = "flowNudgeVariant"

  public static var current: FlowNudgeVariant {
    get {
      UserDefaults.standard.string(forKey: defaultsKey).flatMap(Self.init(rawValue:)) ?? .side
    }
    set { UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey) }
  }

  public var next: FlowNudgeVariant {
    let all = Self.allCases
    return all[(all.firstIndex(of: self)! + 1) % all.count]
  }

  public var title: String {
    switch self {
    case .side: return "Side"
    case .top: return "Drop from top"
    case .peek: return "Peek from top"
    }
  }

  /// Panel hugs the top edge of the screen for the from-above variants.
  public var anchorsToTop: Bool { self != .side }
}

/// Which pill the user tapped on the last nudge; picks the matching exit clip.
public enum FlowNudgeReply {
  case backToWork
  case snooze
  case correct
}
