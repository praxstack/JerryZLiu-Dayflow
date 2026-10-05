//
//  FlowSessionMirrorCore.swift
//  Dayflow
//
//  Testable Flow session/overlay policy without AppKit, timers, or
//  ScreenCaptureKit. FlowSessionMirror (macOS) still owns the singleton,
//  localization, and deadline timers; this is the mockable state machine
//  plan 004 asked for.
//

import Foundation

/// Event sink matching `FlowBridgeForwarding.sendEvent` without `@MainActor`.
public protocol FlowEventSink: AnyObject {
  func sendEvent(_ event: String, payload: [String: Any])
}

public final class MockFlowBridge: FlowEventSink {
  public private(set) var events: [(event: String, payload: [String: Any])] = []

  public init() {}

  public func sendEvent(_ event: String, payload: [String: Any]) {
    events.append((event: event, payload: payload))
  }

  public var eventNames: [String] { events.map(\.event) }
}

public struct FlowSessionMirrorState: Equatable {
  public var snapshot: FlowNativeSnapshot
  public var overlay: FlowOverlayPresentation
  public var isDistracted: Bool
  public var nudgeStreak: Int
  public var snoozed: Bool

  public init(
    snapshot: FlowNativeSnapshot = .idle,
    overlay: FlowOverlayPresentation = .hidden,
    isDistracted: Bool = false,
    nudgeStreak: Int = 0,
    snoozed: Bool = false
  ) {
    self.snapshot = snapshot
    self.overlay = overlay
    self.isDistracted = isDistracted
    self.nudgeStreak = nudgeStreak
    self.snoozed = snoozed
  }
}

/// Overlay copy used by tests. The macOS mirror localizes the same phrases.
public enum FlowSessionMirrorMessages {
  public static let sessionStarted = "Your flow session starts now!"
  public static let breakOver = "Break's over. Back to it!"
  public static let backToWork = "Nice! Keep at it"
}

public final class FlowSessionMirrorCore {
  public private(set) var state: FlowSessionMirrorState
  public weak var webBridge: FlowEventSink?

  public init(state: FlowSessionMirrorState = FlowSessionMirrorState(), webBridge: FlowEventSink? = nil) {
    self.state = state
    self.webBridge = webBridge
  }

  public var overlay: FlowOverlayPresentation { state.overlay }
  public var snapshot: FlowNativeSnapshot { state.snapshot }
  public var isDistracted: Bool { state.isDistracted }

  public static func presentation(for event: FlowPhaseOverlayEvent) -> FlowOverlayPresentation? {
    switch event {
    case .sessionStarted:
      return .toast(message: FlowSessionMirrorMessages.sessionStarted)
    case .onBreak:
      return .onBreak
    case .breakOver:
      return .toast(message: FlowSessionMirrorMessages.breakOver)
    case .hide:
      return .hidden
    case .unchanged:
      return nil
    }
  }

  public func apply(_ newSnapshot: FlowNativeSnapshot) {
    let previous = state.snapshot.phase
    state.snapshot = newSnapshot
    switch (previous, newSnapshot.phase) {
    case (.idle, .active), (.ended, .active):
      state.isDistracted = false
      state.snoozed = false
      state.nudgeStreak = 0
    case (_, .idle), (_, .ended):
      state.isDistracted = false
      state.snoozed = false
    default:
      break
    }
    if let next = Self.presentation(
      for: FlowOverlayMapping.event(from: previous, to: newSnapshot.phase))
    {
      state.overlay = next
    }
  }

  public func agentReportedFocusChange(isDistracted distracted: Bool) {
    guard state.snapshot.phase == .active else { return }
    state.isDistracted = distracted
    if !distracted { state.nudgeStreak = 0 }
    webBridge?.sendEvent(distracted ? "distractionSimulated" : "distractionEnded", payload: [:])
    if !distracted, case .nudge = state.overlay {
      state.overlay = .hidden
    }
  }

  public func agentNudge(message: String) {
    guard let next = mappedOverlay(for: .nudge(message), streakAfter: state.nudgeStreak + 1) else {
      return
    }
    state.nudgeStreak += 1
    state.overlay = next
  }

  public func agentPraise(message: String) {
    guard mappedOverlay(for: .praise(message), streakAfter: state.nudgeStreak) != nil else {
      return
    }
    state.overlay = .toast(message: message)
  }

  public func respondBackToWork() {
    state.isDistracted = false
    state.snoozed = false
    state.nudgeStreak = 0
    webBridge?.sendEvent("overlayAction", payload: ["action": "backToWork"])
    state.overlay = .toast(message: FlowSessionMirrorMessages.backToWork)
  }

  public func simulateDistraction() {
    guard state.snapshot.phase == .active else { return }
    state.isDistracted = true
    webBridge?.sendEvent("distractionSimulated", payload: [:])
    state.snoozed = false
    if let next = mappedOverlay(for: .nudge(""), streakAfter: state.nudgeStreak + 1) {
      state.nudgeStreak += 1
      state.overlay = next
    }
  }

  private func mappedOverlay(
    for action: FlowOverlayAction,
    streakAfter: Int
  ) -> FlowOverlayPresentation? {
    FlowOverlayMapping.overlay(
      for: action,
      phase: state.snapshot.phase,
      alertStyle: state.snapshot.alertStyle,
      snoozed: state.snoozed,
      current: state.overlay,
      nudgeStreakAfterThisNudge: streakAfter
    )
  }
}
