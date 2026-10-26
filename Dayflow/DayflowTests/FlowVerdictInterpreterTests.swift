import XCTest

@testable import Dayflow

final class FlowVerdictInterpreterTests: XCTestCase {
  func testOnTaskJSON() {
    XCTAssertEqual(FlowVerdictInterpreter.parse(#"{"status":"on_task"}"#), .onTask)
  }

  func testOffTaskWithMessage() {
    let parsed = FlowVerdictInterpreter.parseDetails(
      #"{"status":"off_task","message":"Slack"}"#)
    XCTAssertEqual(parsed.decision, .offTask(message: "Slack"))
    XCTAssertTrue(parsed.isOffTask)
    XCTAssertEqual(parsed.overlay, .none)
  }

  func testNudgeAction() {
    XCTAssertEqual(
      FlowVerdictInterpreter.parse(#"{"action":"nudge","message":"Back to PR"}"#),
      .nudge(message: "Back to PR"))
  }

  func testInvalidJSONIsOnTask() {
    XCTAssertEqual(FlowVerdictInterpreter.parse("{invalid}"), .onTask)
    XCTAssertNil(FlowVerdictInterpreter.decode("{invalid}"))
  }

  func testEmptyObjectIsOnTask() {
    XCTAssertEqual(FlowVerdictInterpreter.parse("{}"), .onTask)
    XCTAssertNotNil(FlowVerdictInterpreter.decode("{}"))
  }

  func testGarbageDecodeIsNilSoAgentDoesNotFlipFocus() {
    XCTAssertNil(FlowVerdictInterpreter.decode("not json at all"))
    XCTAssertEqual(FlowVerdictInterpreter.parse("not json at all"), .onTask)
  }

  func testFencedJSONStillParses() {
    let reply = """
      Here you go
      ```json
      {"status":"on_task","action":"none"}
      ```
      """
    XCTAssertEqual(FlowVerdictInterpreter.parse(reply), .onTask)
  }

  func testOffTaskNudgeKeepsStatusIndependentOfOverlay() {
    let parsed = FlowVerdictInterpreter.parseDetails(
      #"{"status":"off_task","action":"nudge","message":"Focus","reason":"slack"}"#)
    XCTAssertEqual(parsed.decision, .nudge(message: "Focus"))
    XCTAssertTrue(parsed.isOffTask)
    XCTAssertEqual(parsed.reason, "slack")
  }
}

final class FlowOverlayMappingTests: XCTestCase {
  func testPhaseTransitionsMatchMirrorApply() {
    XCTAssertEqual(FlowOverlayMapping.event(from: .idle, to: .active), .sessionStarted)
    XCTAssertEqual(FlowOverlayMapping.event(from: .onBreak, to: .active), .breakOver)
    XCTAssertEqual(FlowOverlayMapping.event(from: .active, to: .idle), .hide)
    XCTAssertEqual(FlowOverlayMapping.event(from: .active, to: .ended), .unchanged)
  }

  func testNudgePolicy() {
    XCTAssertEqual(
      FlowOverlayMapping.overlay(
        for: .nudge(""),
        phase: .active,
        alertStyle: .friendly,
        snoozed: false,
        current: .hidden,
        nudgeStreakAfterThisNudge: 2),
      .nudge(message: FlowOverlayMapping.defaultNudgeMessage, escalated: true))
    XCTAssertNil(
      FlowOverlayMapping.overlay(
        for: .nudge("x"),
        phase: .active,
        alertStyle: .quiet,
        snoozed: false,
        current: .hidden,
        nudgeStreakAfterThisNudge: 1))
  }
}
