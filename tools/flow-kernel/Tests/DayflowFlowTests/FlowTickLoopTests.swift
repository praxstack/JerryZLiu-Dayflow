import Foundation
import XCTest
import DayflowFlow

final class FlowTickLoopTests: XCTestCase {
  private let epoch = Date(timeIntervalSince1970: 1_700_000_000)

  private func makeLoop(
    tickSeconds: TimeInterval = 15,
    maxFailures: Int = 3
  ) -> (MockFlowClock, MockFlowScheduler, FlowTickLoop) {
    let clock = MockFlowClock(now: epoch)
    let scheduler = MockFlowScheduler(clock: clock)
    let loop = FlowTickLoop(
      clock: clock,
      scheduler: scheduler,
      tickSeconds: tickSeconds,
      maxFailures: maxFailures
    )
    return (clock, scheduler, loop)
  }

  private func activeSnapshot(endsAt: Int? = nil) -> FlowNativeSnapshot {
    var snapshot = FlowNativeSnapshot()
    snapshot.phase = .active
    snapshot.alertStyle = .friendly
    snapshot.sessionStartedAt = Int(epoch.timeIntervalSince1970)
    snapshot.sessionEndsAt = endsAt
    return snapshot
  }

  // MARK: Idle vs on-task

  func testIdleSessionSkipsTickAndIgnoresOffTaskReply() {
    let (clock, scheduler, loop) = makeLoop()
    XCTAssertEqual(loop.beginTick(), .skip(.idle))

    clock.advance(by: 60)
    scheduler.runDue()
    XCTAssertEqual(loop.mirror.overlay, .hidden)
    XCTAssertFalse(loop.mirror.isDistracted)

    // Even a injected off-task nudge must not fire while idle.
    let finish = loop.finishTick(reply: #"{"status":"off_task","action":"nudge","message":"Slack"}"#)
    XCTAssertEqual(finish.kind, .applied)
    XCTAssertFalse(finish.didFlipFocus)
    XCTAssertEqual(loop.mirror.overlay, .hidden)
    XCTAssertFalse(loop.mirror.isDistracted)
  }

  func testOnTaskTickDoesNotNudgeOrFlipFocus() {
    let (_, _, loop) = makeLoop()
    loop.start(with: activeSnapshot())
    XCTAssertEqual(loop.beginTick(), .begin)

    let finish = loop.finishTick(reply: #"{"status":"on_task","action":"none"}"#)
    XCTAssertEqual(finish.kind, .applied)
    XCTAssertEqual(finish.parsed.decision, .onTask)
    XCTAssertFalse(finish.didFlipFocus)
    XCTAssertFalse(loop.lastReportedOffTask)
    XCTAssertFalse(loop.mirror.isDistracted)
    if case .nudge = loop.mirror.overlay {
      XCTFail("on-task must not present a nudge")
    }
  }

  func testOffTaskNudgeThenOnTaskClosesIncident() {
    let (_, _, loop) = makeLoop()
    loop.start(with: activeSnapshot())
    XCTAssertEqual(loop.beginTick(), .begin)
    _ = loop.finishTick(
      reply: #"{"status":"off_task","action":"nudge","message":"Back to PR"}"#)
    XCTAssertTrue(loop.mirror.isDistracted)
    XCTAssertEqual(
      loop.mirror.overlay,
      .nudge(message: "Back to PR", escalated: false))

    XCTAssertEqual(loop.beginTick(), .begin)
    let back = loop.finishTick(reply: #"{"status":"on_task"}"#)
    XCTAssertTrue(back.didFlipFocus)
    XCTAssertFalse(loop.lastReportedOffTask)
    XCTAssertFalse(loop.mirror.isDistracted)
  }

  // MARK: Fail-safe

  func testUnparseableReplyDoesNotCloseOffTaskIncident() {
    let (_, _, loop) = makeLoop()
    loop.start(with: activeSnapshot())
    XCTAssertEqual(loop.beginTick(), .begin)
    _ = loop.finishTick(
      reply: #"{"status":"off_task","action":"nudge","message":"Slack"}"#)
    XCTAssertTrue(loop.lastReportedOffTask)
    XCTAssertTrue(loop.mirror.isDistracted)

    XCTAssertEqual(loop.beginTick(), .begin)
    let failSafe = loop.finishTick(reply: "not json at all")
    XCTAssertEqual(failSafe.kind, .unparseableFailSafe)
    XCTAssertFalse(failSafe.didFlipFocus)
    XCTAssertEqual(failSafe.parsed, .onTask)
    XCTAssertTrue(loop.lastReportedOffTask)
    XCTAssertTrue(loop.mirror.isDistracted)
    XCTAssertEqual(
      loop.mirror.overlay,
      .nudge(message: "Slack", escalated: false))
  }

  func testConsecutiveFailuresStopTheLoop() {
    let (_, _, loop) = makeLoop(maxFailures: 3)
    loop.start(with: activeSnapshot())
    var last: FlowTickFinish?
    for _ in 1...3 {
      XCTAssertEqual(loop.beginTick(), .begin)
      last = loop.finishTick(reply: nil)
      XCTAssertEqual(last?.kind, .failed)
    }
    XCTAssertEqual(last?.consecutiveFailures, 3)
    XCTAssertEqual(last?.shouldStop, true)
    XCTAssertFalse(loop.running)
    XCTAssertEqual(loop.beginTick(), .skip(.idle))
  }

  func testExpiredSessionRestoresIdle() {
    var snapshot = activeSnapshot(endsAt: Int(epoch.timeIntervalSince1970) - 10)
    snapshot.phase = .active
    let restored = FlowTickPolicy.restoredSnapshot(
      snapshot, nowUnix: Int(epoch.timeIntervalSince1970))
    XCTAssertEqual(restored.phase, .idle)
  }

  // MARK: Clock / scheduler mock (no Foundation Timer)

  func testInjectedClockFiresTickWithoutLiveTimer() {
    let (clock, scheduler, loop) = makeLoop(tickSeconds: 15)
    var dueCount = 0
    loop.onTickDue = { dueCount += 1 }
    loop.start(with: activeSnapshot())
    XCTAssertEqual(dueCount, 0)

    clock.advance(by: 14)
    scheduler.runDue()
    XCTAssertEqual(dueCount, 0)

    clock.advance(by: 1)
    scheduler.runDue()
    XCTAssertEqual(dueCount, 1)
  }

  func testPausedSessionDoesNotFireTick() {
    let (clock, scheduler, loop) = makeLoop(tickSeconds: 15)
    var dueCount = 0
    loop.onTickDue = { dueCount += 1 }
    loop.start(with: activeSnapshot())
    loop.pause()
    clock.advance(by: 30)
    scheduler.runDue()
    XCTAssertEqual(dueCount, 0)
    XCTAssertEqual(loop.beginTick(), .skip(.paused))
  }

  func testInFlightTickIsSkipped() {
    let (_, _, loop) = makeLoop()
    loop.start(with: activeSnapshot())
    XCTAssertEqual(loop.beginTick(), .begin)
    XCTAssertEqual(loop.beginTick(), .skip(.inFlight))
  }

  func testInjectedClockEndsTimedSessionWithoutLiveTimer() {
    let (clock, scheduler, loop) = makeLoop()
    loop.start(with: activeSnapshot(endsAt: Int(epoch.timeIntervalSince1970) + 60))
    clock.advance(by: 59)
    scheduler.runDue()
    XCTAssertEqual(loop.mirror.snapshot.phase, .active)

    clock.advance(by: 1)
    scheduler.runDue()
    XCTAssertEqual(loop.mirror.snapshot.phase, .ended)
    XCTAssertEqual(loop.mirror.overlay, .sessionEnded)
  }
}
