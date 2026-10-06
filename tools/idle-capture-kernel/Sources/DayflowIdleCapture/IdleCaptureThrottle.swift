import Foundation

/// Defaults for idle-throttled screenshot capture (JerryZLiu/Dayflow #286).
///
/// The throttled interval must stay at or under IdleBatchClassifier's
/// `maxAllowedUncoveredGapSeconds` (30s). `idleSecondsAtCapture` measures time
/// since the last *input event*, not time since the last screenshot — so a
/// brief activity blip mid-idle-stretch resets that clock to near-zero for
/// the next screenshot, leaving up to `(throttledIntervalSeconds - 1)` seconds
/// of the previous inter-screenshot gap uncovered. At 30s that worst case is
/// 29s, just inside the 30s limit; anything higher can silently kick the batch
/// out of idle classification and force a full LLM pass.
public enum IdleCaptureDefaults {
  public static let idleThresholdSeconds: TimeInterval = 120
  public static let throttledIntervalSeconds: TimeInterval = 30
  /// Must stay in lockstep with `IdleBatchRules.maxAllowedUncoveredGapSeconds`.
  public static let maxAllowedUncoveredGapSeconds = 30
}

/// User preference for idle-throttled capture. Only an on/off toggle is
/// exposed — threshold/interval values are tuned constants, matching
/// `IdleBatchRules`.
public enum IdleCapturePreferences {
  public static let enabledKey = "idleCaptureThrottleEnabled"

  public static func isEnabled(in defaults: UserDefaults = .standard) -> Bool {
    defaults.object(forKey: enabledKey) as? Bool ?? true
  }

  public static func setEnabled(_ enabled: Bool, in defaults: UserDefaults = .standard) {
    defaults.set(enabled, forKey: enabledKey)
  }

  public static var enabled: Bool {
    get { isEnabled() }
    set { setEnabled(newValue) }
  }
}

/// Combined per-tick decision for ScreenRecorder: whether this firing should
/// write a frame, the idle-aware target cadence, and whether the repeating
/// timer needs to be rebuilt.
public struct IdleCaptureDecision: Equatable {
  public let shouldCapture: Bool
  public let interval: TimeInterval
  public let rescheduleTo: TimeInterval?

  public init(shouldCapture: Bool, interval: TimeInterval, rescheduleTo: TimeInterval?) {
    self.shouldCapture = shouldCapture
    self.interval = interval
    self.rescheduleTo = rescheduleTo
  }
}

/// Pure idle-capture policy. Free of ScreenCaptureKit, AppKit, and
/// DispatchSourceTimer so Linux `swift test` can cover it.
public enum IdleCaptureThrottle {
  /// Effective capture cadence given idle heuristics.
  ///
  /// Missing idle readings never throttle (avoid starving real activity).
  /// When the user already chose a base interval slower than the idle
  /// cadence, stay at that base — throttling must not speed capture up.
  public static func interval(
    baseInterval: TimeInterval,
    idleThrottledInterval: TimeInterval = IdleCaptureDefaults.throttledIntervalSeconds,
    idleSeconds: Int?,
    idleThresholdSeconds: TimeInterval = IdleCaptureDefaults.idleThresholdSeconds,
    enabled: Bool = true
  ) -> TimeInterval {
    guard enabled else { return baseInterval }
    guard let idleSeconds, TimeInterval(idleSeconds) >= idleThresholdSeconds else {
      return baseInterval
    }
    return max(baseInterval, idleThrottledInterval)
  }

  /// Time-since-last-capture gate. The first frame (no prior capture) always
  /// fires. Later ticks fire only once `interval` has elapsed.
  public static func shouldCapture(
    now: Date,
    lastCapture: Date?,
    interval: TimeInterval
  ) -> Bool {
    guard let lastCapture else { return true }
    return now.timeIntervalSince(lastCapture) >= interval
  }

  /// Returns `target` when the repeating timer must be rebuilt.
  public static func rescheduleInterval(
    current: TimeInterval?,
    target: TimeInterval
  ) -> TimeInterval? {
    guard current != target else { return nil }
    return target
  }

  /// One-tick policy used by ScreenRecorder.
  ///
  /// `shouldCapture` is evaluated against the *currently scheduled* interval
  /// so the tick that crosses the idle threshold still writes a frame. That
  /// keeps the inter-screenshot gap at the old cadence (10s) rather than
  /// stretching to ~40s, which would exceed IdleBatchClassifier's 30s
  /// uncovered-gap limit. The new cadence only applies starting at the next
  /// scheduled fire.
  public static func decide(
    now: Date,
    lastCapture: Date?,
    idleSeconds: Int?,
    enabled: Bool,
    baseInterval: TimeInterval,
    idleThrottledInterval: TimeInterval = IdleCaptureDefaults.throttledIntervalSeconds,
    idleThresholdSeconds: TimeInterval = IdleCaptureDefaults.idleThresholdSeconds,
    scheduledInterval: TimeInterval?
  ) -> IdleCaptureDecision {
    let target = interval(
      baseInterval: baseInterval,
      idleThrottledInterval: idleThrottledInterval,
      idleSeconds: idleSeconds,
      idleThresholdSeconds: idleThresholdSeconds,
      enabled: enabled
    )
    let captureGate = scheduledInterval ?? target
    return IdleCaptureDecision(
      shouldCapture: shouldCapture(now: now, lastCapture: lastCapture, interval: captureGate),
      interval: target,
      rescheduleTo: rescheduleInterval(current: scheduledInterval, target: target)
    )
  }
}
