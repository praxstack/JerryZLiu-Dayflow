import XCTest

@testable import Dayflow

final class FlowVerdictInterpreterTests: XCTestCase {
  func testGarbageIsUnparseable() {
    XCTAssertNil(FlowVerdictInterpreter.parse("not json at all"))
    XCTAssertEqual(FlowVerdictInterpreter.jsonObjects(in: "hello"), [])
  }

  func testPlainVerdict() throws {
    let reply = #"{"status":"off_task","action":"nudge","message":"Focus","reason":"slack"}"#
    let verdict = try XCTUnwrap(FlowVerdictInterpreter.parse(reply))
    XCTAssertEqual(verdict.status, "off_task")
    XCTAssertEqual(verdict.action, "nudge")
    XCTAssertEqual(verdict.message, "Focus")
    XCTAssertEqual(verdict.reason, "slack")
  }

  func testFencedJsonStillParses() throws {
    let reply = """
      Here you go
      ```json
      {"status":"on_task","action":"none"}
      ```
      """
    let verdict = try XCTUnwrap(FlowVerdictInterpreter.parse(reply))
    XCTAssertEqual(verdict.status, "on_task")
    XCTAssertEqual(verdict.action, "none")
  }

  func testSecondObjectIsIgnoredForVerdict() throws {
    let reply = #"{"status":"on_task"}{"timeline":[]}"#
    let objects = FlowVerdictInterpreter.jsonObjects(in: reply)
    XCTAssertEqual(objects.count, 2)
    let verdict = try XCTUnwrap(FlowVerdictInterpreter.parse(reply))
    XCTAssertEqual(verdict.status, "on_task")
    XCTAssertNil(verdict.action)
  }

  func testEmptyObjectIsValidOnTaskDefault() throws {
    let verdict = try XCTUnwrap(FlowVerdictInterpreter.parse("{}"))
    XCTAssertNil(verdict.status)
    XCTAssertNil(verdict.action)
  }

  func testCompletedGoalsRoundTrip() throws {
    let reply = #"{"status":"on_task","completed_goals":["g1","g2"]}"#
    let verdict = try XCTUnwrap(FlowVerdictInterpreter.parse(reply))
    XCTAssertEqual(verdict.completed_goals, ["g1", "g2"])
  }
}
