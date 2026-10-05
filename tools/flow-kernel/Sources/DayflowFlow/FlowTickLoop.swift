//
//  FlowTickLoop.swift
//  Dayflow
//
//  Timer-free Flow tick / deadline decision loop. Tests inject a clock and
//  scheduler; FlowSessionMirror and FlowDistractionAgent call the same
//  policy so ScreenCaptureKit and live Codex stay out of the kernel.
//
//  Compiled into the macOS app via the DayflowFlow PBXFileSystemSynchronizedRootGroup
//  in Dayflow.xcodeproj and into Linux/SwiftPM tests via this package.
//

import Foundation

public protocol FlowClock: AnyObject {
  var now: Date { get }
}

public final class SystemFlowClock: FlowClock {
  public init() {}
  public var now: Date { Date() }
}

public final class MockFlowClock: FlowClock {
  public var now: Date

  public init(now: Date) {
    self.now = now
  }

  public func advance(by interval: TimeInterval) {
    now = now.addingTimeInterval(interval)
  }
}

public protocol FlowScheduler: AnyObject {
  func schedule(id: String, after interval: TimeInterval, execute: @escaping () -> Void)
  func cancel(id: String)
}

public final class MockFlowScheduler: FlowScheduler {
  public struct Item {
    public var id: String
    public var fireAt: Date
    public var execute: () -> Void
  }

  public private(set) var items: [Item] = []
  public let clock: FlowClock

  public init(clock: FlowClock) {
    self.clock = clock
  }

  public func schedule(id: String, after interval: TimeInterval, execute: @escaping () -> Void) {
    cancel(id: id)
    items.append(
      Item(id: id, fireAt: clock.now.addingTimeInterval(interval), execute: execute))
  }

  public func cancel(id: String) {
    items.removeAll { $0.id == id }
  }

  public func runDue() {
    let now = clock.now
    let due = items.filter { $0.fireAt <= now }
    items.removeAll { $0.fireAt <= now }
    for item in due {
      item.execute()
    }
  }
}

public enum FlowTickSkipReason: Equatable {
  case idle
  case paused
  case inFlight
  case disabled
}

public enum FlowTickBegin: Equatable {
  case skip(FlowTickSkipReason)
  case begin
}

public enum FlowTickFinishKind: Equatable {
  case applied
  case unparseableFailSafe
  case failed
}

public struct FlowTickFinish: Equatable {
  public var kind: FlowTickFinishKind
  public var parsed: FlowParsedVerdict
  public var didFlipFocus: Bool
  public var consecutiveFailures: Int
  public var shouldStop: Bool

  public init(
    kind: FlowTickFinishKind,
    parsed: FlowParsedVerdict,
    didFlipFocus: Bool,
    consecutiveFailures: Int,
    shouldStop: Bool
  ) {
    self.kind = kind
    self.parsed = parsed
    self.didFlipFocus = didFlipFocus
    self.consecutiveFailures = consecutiveFailures
    self.shouldStop = shouldStop
  }
}

public enum FlowDeadlineEffect: Equatable {
  case clearSnooze
  case snoozeRenudge(escalated: Bool)
  case sessionEnded
  case breakEnded
}

/// Pure tick / deadline policy used by the live AppKit singletons and by
/// `FlowTickLoop` in Linux tests.
public enum FlowTickPolicy {
  public static let minimumTickSeconds: TimeInterval = 5
  public static let minimumDeadlineDelay: TimeInterval = 0.5

  public static func beginTick(
    running: Bool,
    paused: Bool,
    inFlight: Bool,
    enabled: Bool,
    phase: FlowPhase
  ) -> FlowTickBegin {
    if !enabled {
      return .skip(.disabled)
    }
    switch phase {
    case .idle, .ended:
      return .skip(.idle)
    case .onBreak, .active:
      // Breaks pause via the `paused` flag so debug `tickNow()` still works.
      break
    }
    if !running {
      return .skip(.idle)
    }
    if paused {
      return .skip(.paused)
    }
    if inFlight {
      return .skip(.inFlight)
    }
    return .begin
  }

  public static func finishTick(
    reply: String?,
    lastReportedOffTask: Bool,
    consecutiveFailures: Int,
    maxFailures: Int
  ) -> FlowTickFinish {
    guard let reply else {
      let consecutive = consecutiveFailures + 1
      return FlowTickFinish(
        kind: .failed,
        parsed: .onTask,
        didFlipFocus: false,
        consecutiveFailures: consecutive,
        shouldStop: consecutive >= max(1, maxFailures)
      )
    }
    guard let verdict = FlowVerdictInterpreter.decode(reply) else {
      return FlowTickFinish(
        kind: .unparseableFailSafe,
        parsed: .onTask,
        didFlipFocus: false,
        consecutiveFailures: 0,
        shouldStop: false
      )
    }
    let parsed = FlowVerdictInterpreter.interpret(verdict)
    return FlowTickFinish(
      kind: .applied,
      parsed: parsed,
      didFlipFocus: parsed.isOffTask != lastReportedOffTask,
      consecutiveFailures: 0,
      shouldStop: false
    )
  }

  public static func nextDeadline(
    now: Date,
    snapshot: FlowNativeSnapshot,
    snoozeUntil: Date?
  ) -> Date? {
    var deadlines: [Date] = []
    if snapshot.phase == .active, let endsAt = snapshot.sessionEndsAt {
      deadlines.append(Date(timeIntervalSince1970: TimeInterval(endsAt)))
    }
    if snapshot.phase == .onBreak, let endsAt = snapshot.breakEndsAt {
      deadlines.append(Date(timeIntervalSince1970: TimeInterval(endsAt)))
    }
    if let snoozeUntil {
      deadlines.append(snoozeUntil)
    }
    return deadlines.min()
  }

  public static func scheduleDelay(until deadline: Date, now: Date) -> TimeInterval {
    max(minimumDeadlineDelay, deadline.timeIntervalSince(now))
  }

  public static func deadlineEffects(
    now: Date,
    snapshot: FlowNativeSnapshot,
    snoozeUntil: Date?,
    isDistracted: Bool,
    nudgeStreak: Int
  ) -> [FlowDeadlineEffect] {
    var effects: [FlowDeadlineEffect] = []
    var phase = snapshot.phase
    let nowUnix = Int(now.timeIntervalSince1970)

    if let snoozeUntil, snoozeUntil <= now {
      effects.append(.clearSnooze)
      if isDistracted, phase == .active, snapshot.alertStyle != .quiet {
        effects.append(.snoozeRenudge(escalated: nudgeStreak + 1 >= 2))
      }
    }

    if phase == .active, let endsAt = snapshot.sessionEndsAt, endsAt <= nowUnix {
      effects.append(.sessionEnded)
      phase = .ended
    }

    if phase == .onBreak, let endsAt = snapshot.breakEndsAt, endsAt <= nowUnix {
      effects.append(.breakEnded)
    }

    return effects
  }

  public static func restoredSnapshot(
    _ snapshot: FlowNativeSnapshot, nowUnix: Int
  ) -> FlowNativeSnapshot {
    if snapshot.phase != .idle, let endsAt = snapshot.sessionEndsAt, endsAt <= nowUnix {
      return .idle
    }
    return snapshot
  }
}

/// Testable session tick loop. The live `FlowSessionMirror` singleton keeps
/// Foundation `Timer`s and calls `FlowTickPolicy`; this type is the same
/// decisions driven by an injected clock/scheduler.
public final class FlowTickLoop {
  public static let tickScheduleID = "flow.tick"
  public static let deadlineScheduleID = "flow.deadline"

  public let clock: FlowClock
  public let scheduler: FlowScheduler
  public let mirror: FlowSessionMirrorCore
  public var tickSeconds: TimeInterval
  public var maxFailures: Int
  public var agentEnabled: Bool
  public var onTickDue: (() -> Void)?

  public private(set) var running = false
  public private(set) var paused = false
  public private(set) var tickInFlight = false
  public private(set) var lastReportedOffTask = false
  public private(set) var consecutiveFailures = 0
  public private(set) var snoozeUntil: Date?

  public init(
    clock: FlowClock,
    scheduler: FlowScheduler,
    mirror: FlowSessionMirrorCore = FlowSessionMirrorCore(),
    tickSeconds: TimeInterval = 15,
    maxFailures: Int = 3,
    agentEnabled: Bool = true
  ) {
    self.clock = clock
    self.scheduler = scheduler
    self.mirror = mirror
    self.tickSeconds = tickSeconds
    self.maxFailures = maxFailures
    self.agentEnabled = agentEnabled
  }

  public func start(with snapshot: FlowNativeSnapshot) {
    stop()
    mirror.apply(snapshot)
    running = true
    paused = false
    tickInFlight = false
    lastReportedOffTask = false
    consecutiveFailures = 0
    snoozeUntil = nil
    armTick()
    armDeadline()
  }

  public func pause() {
    paused = true
    scheduler.cancel(id: Self.tickScheduleID)
  }

  public func resume() {
    paused = false
    armTick()
  }

  public func stop() {
    running = false
    paused = false
    tickInFlight = false
    scheduler.cancel(id: Self.tickScheduleID)
    scheduler.cancel(id: Self.deadlineScheduleID)
  }

  @discardableResult
  public func beginTick() -> FlowTickBegin {
    let begin = FlowTickPolicy.beginTick(
      running: running,
      paused: paused,
      inFlight: tickInFlight,
      enabled: agentEnabled,
      phase: mirror.snapshot.phase
    )
    if case .begin = begin {
      tickInFlight = true
    }
    return begin
  }

  @discardableResult
  public func finishTick(reply: String?) -> FlowTickFinish {
    tickInFlight = false
    let result = FlowTickPolicy.finishTick(
      reply: reply,
      lastReportedOffTask: lastReportedOffTask,
      consecutiveFailures: consecutiveFailures,
      maxFailures: maxFailures
    )
    consecutiveFailures = result.consecutiveFailures

    guard running, mirror.snapshot.phase == .active else {
      if result.shouldStop { stop() }
      return FlowTickFinish(
        kind: result.kind,
        parsed: result.parsed,
        didFlipFocus: false,
        consecutiveFailures: result.consecutiveFailures,
        shouldStop: result.shouldStop
      )
    }

    switch result.kind {
    case .applied:
      apply(result)
    case .unparseableFailSafe, .failed:
      break
    }

    if result.shouldStop {
      stop()
    }
    return result
  }

  public func handleDeadline() {
    let effects = FlowTickPolicy.deadlineEffects(
      now: clock.now,
      snapshot: mirror.snapshot,
      snoozeUntil: snoozeUntil,
      isDistracted: mirror.isDistracted,
      nudgeStreak: mirror.state.nudgeStreak
    )
    applyDeadlineEffects(effects)
    armDeadline()
  }

  private func apply(_ result: FlowTickFinish) {
    if result.didFlipFocus {
      lastReportedOffTask = result.parsed.isOffTask
      mirror.agentReportedFocusChange(isDistracted: result.parsed.isOffTask)
    }
    switch result.parsed.overlay {
    case .none:
      break
    case .nudge(let message):
      mirror.agentNudge(message: message)
    case .praise(let message):
      mirror.agentPraise(message: message)
    }
  }

  private func applyDeadlineEffects(_ effects: [FlowDeadlineEffect]) {
    for effect in effects {
      switch effect {
      case .clearSnooze:
        snoozeUntil = nil
        mirror.applyDeadlineEffect(effect)
      case .snoozeRenudge:
        mirror.applyDeadlineEffect(effect)
      case .sessionEnded:
        mirror.applyDeadlineEffect(effect)
        stop()
      case .breakEnded:
        mirror.applyDeadlineEffect(effect)
      }
    }
  }

  private func armTick() {
    scheduler.cancel(id: Self.tickScheduleID)
    guard running, !paused else { return }
    let interval = max(FlowTickPolicy.minimumTickSeconds, tickSeconds)
    scheduler.schedule(id: Self.tickScheduleID, after: interval) { [weak self] in
      self?.handleScheduledTick()
    }
  }

  private func handleScheduledTick() {
    if running, !paused {
      onTickDue?()
    }
    armTick()
  }

  private func armDeadline() {
    scheduler.cancel(id: Self.deadlineScheduleID)
    guard
      let nearest = FlowTickPolicy.nextDeadline(
        now: clock.now, snapshot: mirror.snapshot, snoozeUntil: snoozeUntil)
    else { return }
    let delay = FlowTickPolicy.scheduleDelay(until: nearest, now: clock.now)
    scheduler.schedule(id: Self.deadlineScheduleID, after: delay) { [weak self] in
      self?.handleDeadline()
    }
  }
}
