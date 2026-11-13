import XCTest

@testable import Dayflow

final class GemmaBackupProviderTests: XCTestCase {
  func testExtractGenerativeTextSkipsThoughtParts() {
    let parts: [[String: Any]] = [
      ["thought": true, "text": "internal reasoning that is not JSON"],
      ["text": "{\"title\": \"Worked on Dayflow\"}"],
    ]

    let text = GemmaBackupProvider.extractGenerativeText(from: parts)

    XCTAssertEqual(text, "{\"title\": \"Worked on Dayflow\"}")
  }

  func testExtractGenerativeTextJoinsMultipleVisibleParts() {
    let parts: [[String: Any]] = [
      ["text": "{\"apps\": ["],
      ["thought": true, "text": "planning"],
      ["text": "\"Safari\"], \"summary\": \"Browsed\"}"],
    ]

    let text = GemmaBackupProvider.extractGenerativeText(from: parts)

    XCTAssertEqual(text, "{\"apps\": [\"Safari\"], \"summary\": \"Browsed\"}")
  }

  func testExtractGenerativeTextReturnsNilWhenOnlyThoughtParts() {
    let parts: [[String: Any]] = [
      ["thought": true, "text": "only reasoning"],
    ]

    XCTAssertNil(GemmaBackupProvider.extractGenerativeText(from: parts))
  }
}
