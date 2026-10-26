import XCTest

@testable import Dayflow

final class FlowNativeSnapshotTests: XCTestCase {
  func testCodableRoundTrip() throws {
    var snapshot = FlowNativeSnapshot()
    snapshot.phase = .active
    snapshot.alertStyle = .feisty
    snapshot.sessionEndsAt = 1_700_000_000
    snapshot.sessionStartedAt = 1_699_996_400
    snapshot.goals = ["Ship kernel"]
    snapshot.goalTasks = [FlowGoalTask(id: "goal-0", title: "Ship kernel")]
    let data = try JSONEncoder().encode(snapshot)
    let decoded = try JSONDecoder().decode(FlowNativeSnapshot.self, from: data)
    XCTAssertEqual(decoded, snapshot)
  }

  func testPhaseRawValues() {
    XCTAssertEqual(FlowPhase.onBreak.rawValue, "break")
    XCTAssertNil(FlowPhase(rawValue: "focusing"))
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
}
