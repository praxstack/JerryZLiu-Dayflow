import XCTest

@testable import Dayflow

final class TimelineFailureSummaryDisplayTests: XCTestCase {
  func testKeepsSummaryWhenAutomaticRetryStillPossible() {
    let stored =
      "The AI's reply came back jumbled, so Dayflow couldn't turn it into cards. This usually sorts itself out, and Dayflow will try again automatically."

    let displayed = TimelineFailureSummaryDisplay.displayedSummary(
      storedSummary: stored,
      automaticRetryStillPossible: true
    )

    XCTAssertEqual(displayed, stored)
  }

  func testReplacesAutomaticRetrySentenceWhenNoLongerEligible() {
    let stored =
      "Dayflow couldn't reach Gemini because the connection dropped or its servers were busy. Dayflow will try again automatically."

    let displayed = TimelineFailureSummaryDisplay.displayedSummary(
      storedSummary: stored,
      automaticRetryStillPossible: false
    )

    XCTAssertFalse(displayed.contains("Dayflow will try again automatically."))
    XCTAssertTrue(displayed.contains(TimelineFailureSummaryDisplay.manualRetrySentence))
  }

  func testReplacesLegacyAutomaticRetryCopy() {
    let stored =
      "This time couldn't be turned into cards yet. Dayflow will try again automatically. Your recording is saved."

    let displayed = TimelineFailureSummaryDisplay.displayedSummary(
      storedSummary: stored,
      automaticRetryStillPossible: false
    )

    XCTAssertEqual(
      displayed,
      "This time couldn't be turned into cards yet. Use Retry when you're ready. Your recording is saved."
    )
  }
}
