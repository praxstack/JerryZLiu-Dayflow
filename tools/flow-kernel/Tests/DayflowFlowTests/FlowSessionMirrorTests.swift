import Foundation
import XCTest
import DayflowFlow

final class FlowSessionMirrorTests: XCTestCase {
  func testIdleToActivePublishesSessionStartedOverlay() {
    let mirror = FlowSessionMirrorCore()
    var snapshot = FlowNativeSnapshot()
    snapshot.phase = .active
    snapshot.alertStyle = .friendly
    mirror.apply(snapshot)
    XCTAssertEqual(
      mirror.overlay, .toast(message: FlowSessionMirrorMessages.sessionStarted))
    XCTAssertFalse(mirror.isDistracted)
    XCTAssertEqual(mirror.state.nudgeStreak, 0)
  }

  func testActiveToOnBreakPublishesBreakOverlay() {
    let mirror = FlowSessionMirrorCore()
    var active = FlowNativeSnapshot()
    active.phase = .active
    mirror.apply(active)
    var onBreak = FlowNativeSnapshot()
    onBreak.phase = .onBreak
    mirror.apply(onBreak)
    XCTAssertEqual(mirror.overlay, .onBreak)
  }

  func testBreakToActivePublishesBreakOver() {
    let mirror = FlowSessionMirrorCore()
    var onBreak = FlowNativeSnapshot()
    onBreak.phase = .onBreak
    mirror.apply(onBreak)
    var active = FlowNativeSnapshot()
    active.phase = .active
    mirror.apply(active)
    XCTAssertEqual(
      mirror.overlay, .toast(message: FlowSessionMirrorMessages.breakOver))
  }

  func testActiveToIdleHidesOverlay() {
    let mirror = FlowSessionMirrorCore()
    var active = FlowNativeSnapshot()
    active.phase = .active
    mirror.apply(active)
    mirror.apply(.idle)
    XCTAssertEqual(mirror.overlay, .hidden)
    XCTAssertFalse(mirror.isDistracted)
  }

  func testMockBridgeRecordsFocusChangeAndNudge() {
    let bridge = MockFlowBridge()
    let mirror = FlowSessionMirrorCore(webBridge: bridge)
    var snapshot = FlowNativeSnapshot()
    snapshot.phase = .active
    snapshot.alertStyle = .friendly
    mirror.apply(snapshot)
    mirror.agentReportedFocusChange(isDistracted: true)
    XCTAssertEqual(bridge.eventNames, ["distractionSimulated"])
    XCTAssertTrue(mirror.isDistracted)
    mirror.agentNudge(message: "Slack is a rabbit hole")
    XCTAssertEqual(
      mirror.overlay,
      .nudge(message: "Slack is a rabbit hole", escalated: false))
    mirror.respondBackToWork()
    XCTAssertEqual(bridge.eventNames, ["distractionSimulated", "overlayAction"])
    XCTAssertEqual(bridge.events.last?.payload["action"] as? String, "backToWork")
    XCTAssertFalse(mirror.isDistracted)
    XCTAssertEqual(
      mirror.overlay, .toast(message: FlowSessionMirrorMessages.backToWork))
  }

  func testQuietModeSuppressesNudge() {
    let bridge = MockFlowBridge()
    let mirror = FlowSessionMirrorCore(webBridge: bridge)
    var snapshot = FlowNativeSnapshot()
    snapshot.phase = .active
    snapshot.alertStyle = .quiet
    mirror.apply(snapshot)
    mirror.simulateDistraction()
    XCTAssertTrue(mirror.isDistracted)
    XCTAssertEqual(bridge.eventNames, ["distractionSimulated"])
    XCTAssertEqual(mirror.overlay, .toast(message: FlowSessionMirrorMessages.sessionStarted))
  }

  func testRepeatNudgeEscalates() {
    let mirror = FlowSessionMirrorCore()
    var snapshot = FlowNativeSnapshot()
    snapshot.phase = .active
    snapshot.alertStyle = .feisty
    mirror.apply(snapshot)
    mirror.agentNudge(message: "First")
    mirror.agentNudge(message: "Second")
    XCTAssertEqual(mirror.overlay, .nudge(message: "Second", escalated: true))
  }

  func testPresentationMappingIsExhaustive() {
    XCTAssertEqual(
      FlowSessionMirrorCore.presentation(for: .sessionStarted),
      .toast(message: FlowSessionMirrorMessages.sessionStarted))
    XCTAssertEqual(FlowSessionMirrorCore.presentation(for: .onBreak), .onBreak)
    XCTAssertEqual(
      FlowSessionMirrorCore.presentation(for: .breakOver),
      .toast(message: FlowSessionMirrorMessages.breakOver))
    XCTAssertEqual(FlowSessionMirrorCore.presentation(for: .hide), .hidden)
    XCTAssertNil(FlowSessionMirrorCore.presentation(for: .unchanged))
  }
}
