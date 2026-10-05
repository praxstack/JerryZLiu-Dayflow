import Foundation
import XCTest
import DayflowFlow

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
    XCTAssertEqual(parsed.message, "Slack")
  }

  func testNudgeAction() {
    XCTAssertEqual(
      FlowVerdictInterpreter.parse(#"{"action":"nudge","message":"Back to PR"}"#),
      .nudge(message: "Back to PR"))
  }

  func testInvalidJSONIsOnTask() {
    XCTAssertEqual(FlowVerdictInterpreter.parse("{invalid}"), .onTask)
    XCTAssertNil(FlowVerdictInterpreter.decode("{invalid}"))
    XCTAssertEqual(FlowVerdictInterpreter.jsonObjects(in: "hello"), [])
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
    XCTAssertEqual(FlowVerdictInterpreter.decode(reply)?.action, "none")
  }

  func testSecondObjectIsIgnoredForVerdict() {
    let reply = #"{"status":"on_task"}{"timeline":[]}"#
    XCTAssertEqual(FlowVerdictInterpreter.jsonObjects(in: reply).count, 2)
    XCTAssertEqual(FlowVerdictInterpreter.parse(reply), .onTask)
  }

  func testCompletedGoalsRoundTrip() {
    let parsed = FlowVerdictInterpreter.parseDetails(
      #"{"status":"on_task","completed_goals":["g1","g2"]}"#)
    XCTAssertEqual(parsed.completedGoals, ["g1", "g2"])
  }

  func testOffTaskNudgeKeepsStatusIndependentOfOverlay() {
    let parsed = FlowVerdictInterpreter.parseDetails(
      #"{"status":"off_task","action":"nudge","message":"Focus","reason":"slack"}"#)
    XCTAssertEqual(parsed.decision, .nudge(message: "Focus"))
    XCTAssertTrue(parsed.isOffTask)
    XCTAssertEqual(parsed.overlay, .nudge("Focus"))
    XCTAssertEqual(parsed.reason, "slack")
  }

  func testPraiseRequiresNonEmptyMessage() {
    XCTAssertEqual(
      FlowVerdictInterpreter.parse(#"{"action":"praise","message":"Nice stretch"}"#),
      .praise(message: "Nice stretch"))
    XCTAssertEqual(
      FlowVerdictInterpreter.parse(#"{"action":"praise"}"#),
      .onTask)
  }

  func testParseData() {
    let data = Data(#"{"status":"off_task","message":"X"}"#.utf8)
    XCTAssertEqual(FlowVerdictInterpreter.parse(data), .offTask(message: "X"))
  }
}

final class FlowOverlayMappingTests: XCTestCase {
  func testPhaseTransitions() {
    XCTAssertEqual(
      FlowOverlayMapping.event(from: .idle, to: .active), .sessionStarted)
    XCTAssertEqual(
      FlowOverlayMapping.event(from: .ended, to: .active), .sessionStarted)
    XCTAssertEqual(
      FlowOverlayMapping.event(from: .active, to: .onBreak), .onBreak)
    XCTAssertEqual(
      FlowOverlayMapping.event(from: .idle, to: .onBreak), .onBreak)
    XCTAssertEqual(
      FlowOverlayMapping.event(from: .onBreak, to: .active), .breakOver)
    XCTAssertEqual(
      FlowOverlayMapping.event(from: .active, to: .idle), .hide)
    XCTAssertEqual(
      FlowOverlayMapping.event(from: .active, to: .ended), .unchanged)
    XCTAssertEqual(
      FlowOverlayMapping.event(from: .active, to: .active), .unchanged)
  }

  func testNudgeSuppressedWhenQuietOrSnoozed() {
    XCTAssertNil(
      FlowOverlayMapping.overlay(
        for: .nudge("Back"),
        phase: .active,
        alertStyle: .quiet,
        snoozed: false,
        current: .hidden,
        nudgeStreakAfterThisNudge: 1))
    XCTAssertNil(
      FlowOverlayMapping.overlay(
        for: .nudge("Back"),
        phase: .active,
        alertStyle: .friendly,
        snoozed: true,
        current: .hidden,
        nudgeStreakAfterThisNudge: 1))
    XCTAssertNil(
      FlowOverlayMapping.overlay(
        for: .nudge("Back"),
        phase: .idle,
        alertStyle: .friendly,
        snoozed: false,
        current: .hidden,
        nudgeStreakAfterThisNudge: 1))
  }

  func testNudgeEmptyMessageUsesDefaultAndEscalatesOnRepeat() {
    XCTAssertEqual(
      FlowOverlayMapping.overlay(
        for: .nudge(""),
        phase: .active,
        alertStyle: .friendly,
        snoozed: false,
        current: .hidden,
        nudgeStreakAfterThisNudge: 1),
      .nudge(message: FlowOverlayMapping.defaultNudgeMessage, escalated: false))
    XCTAssertEqual(
      FlowOverlayMapping.overlay(
        for: .nudge("Focus"),
        phase: .active,
        alertStyle: .feisty,
        snoozed: false,
        current: .hidden,
        nudgeStreakAfterThisNudge: 2),
      .nudge(message: "Focus", escalated: true))
  }

  func testPraiseSuppressedDuringNudge() {
    XCTAssertNil(
      FlowOverlayMapping.overlay(
        for: .praise("Nice"),
        phase: .active,
        alertStyle: .friendly,
        snoozed: false,
        current: .nudge(message: "Hey", escalated: false),
        nudgeStreakAfterThisNudge: 1))
    XCTAssertEqual(
      FlowOverlayMapping.overlay(
        for: .praise("Nice"),
        phase: .active,
        alertStyle: .friendly,
        snoozed: false,
        current: .hidden,
        nudgeStreakAfterThisNudge: 1),
      .toast(message: "Nice"))
  }
}

final class FlowNativeSnapshotTests: XCTestCase {
  func testCodableRoundTrip() throws {
    var snapshot = FlowNativeSnapshot()
    snapshot.phase = .active
    snapshot.alertStyle = .feisty
    snapshot.sessionEndsAt = 1_700_000_000
    snapshot.sessionStartedAt = 1_699_996_400
    snapshot.alwaysOn = false
    snapshot.goals = ["Ship kernel"]
    snapshot.goalTasks = [FlowGoalTask(id: "goal-0", title: "Ship kernel")]

    let data = try JSONEncoder().encode(snapshot)
    let decoded = try JSONDecoder().decode(FlowNativeSnapshot.self, from: data)
    XCTAssertEqual(decoded, snapshot)
    XCTAssertEqual(decoded.phase, .active)
    XCTAssertEqual(decoded.alertStyle, .feisty)
  }

  func testPhaseRawValues() throws {
    XCTAssertEqual(FlowPhase.onBreak.rawValue, "break")
    XCTAssertEqual(FlowPhase(rawValue: "break"), .onBreak)
    XCTAssertNil(FlowPhase(rawValue: "focusing"))
  }

  func testPersistAndLoad() {
    let defaults = UserDefaults(suiteName: "flow.kernel.snapshot.tests")!
    defaults.removePersistentDomain(forName: "flow.kernel.snapshot.tests")
    var snapshot = FlowNativeSnapshot()
    snapshot.phase = .onBreak
    snapshot.breakEndsAt = 42
    snapshot.persist(defaults: defaults)
    let loaded = FlowNativeSnapshot.loadPersisted(defaults: defaults)
    XCTAssertEqual(loaded.phase, .onBreak)
    XCTAssertEqual(loaded.breakEndsAt, 42)
  }

  func testBridgePayloadRoundTrip() {
    var snapshot = FlowNativeSnapshot()
    snapshot.phase = .active
    snapshot.alertStyle = .quiet
    snapshot.sessionStartedAt = 100
    snapshot.goals = ["PR"]
    snapshot.goalTasks = [FlowGoalTask(id: "g1", title: "PR")]
    let rebuilt = FlowNativeSnapshot(bridgePayload: snapshot.bridgePayload)
    XCTAssertEqual(rebuilt?.phase, .active)
    XCTAssertEqual(rebuilt?.alertStyle, .quiet)
    XCTAssertEqual(rebuilt?.goals, ["PR"])
    XCTAssertEqual(rebuilt?.goalTasks, [FlowGoalTask(id: "g1", title: "PR")])
  }

  func testBridgePayloadRejectsUnknownPhase() {
    XCTAssertNil(FlowNativeSnapshot(bridgePayload: ["phase": "focusing"]))
    XCTAssertNil(FlowNativeSnapshot(bridgePayload: [:]))
  }
}
