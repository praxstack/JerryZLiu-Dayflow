import XCTest

@testable import Dayflow

/// macOS copy of the Linux kernel tick-loop characterization tests.
/// Full clock/scheduler coverage lives in tools/flow-kernel.
final class FlowTickLoopTests: XCTestCase {
  private let epoch = Date(timeIntervalSince1970: 1_700_000_000)

  private func makeLoop() -> FlowTickLoop {
    let clock = MockFlowClock(now: epoch)
    return FlowTickLoop(
      clock: clock,
      scheduler: MockFlowScheduler(clock: clock)
    )
  }

  private func activeSnapshot() -> FlowNativeSnapshot {
    var snapshot = FlowNativeSnapshot()
    snapshot.phase = .active
    snapshot.alertStyle = .friendly
    snapshot.sessionStartedAt = Int(epoch.timeIntervalSince1970)
    return snapshot
  }

  func testIdleSessionSkipsTick() {
    let loop = makeLoop()
    XCTAssertEqual(loop.beginTick(), .skip(.idle))
  }

  func testOnTaskTickDoesNotNudge() {
    let loop = makeLoop()
    loop.start(with: activeSnapshot())
    XCTAssertEqual(loop.beginTick(), .begin)
    let finish = loop.finishTick(reply: #"{"status":"on_task","action":"none"}"#)
    XCTAssertEqual(finish.kind, .applied)
    XCTAssertFalse(loop.mirror.isDistracted)
  }

  func testUnparseableReplyDoesNotCloseOffTaskIncident() {
    let loop = makeLoop()
    loop.start(with: activeSnapshot())
    _ = loop.beginTick()
    _ = loop.finishTick(
      reply: #"{"status":"off_task","action":"nudge","message":"Slack"}"#)
    _ = loop.beginTick()
    let failSafe = loop.finishTick(reply: "not json at all")
    XCTAssertEqual(failSafe.kind, .unparseableFailSafe)
    XCTAssertTrue(loop.lastReportedOffTask)
    XCTAssertTrue(loop.mirror.isDistracted)
  }
}
