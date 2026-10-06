import XCTest

@testable import Dayflow

final class DailyRecapCardsTextTests: XCTestCase {
  func testEmptyCardListReturnsNoActivitiesMessage() {
    let text = DailyRecapGenerator.makeCardsText(day: "2026-03-11", cards: [])
    XCTAssertTrue(text.lowercased().contains("no timeline activities"))
  }

  func testProcessingFailedCardsAreOmitted() {
    let cards = [
      card(title: "Processing failed", summary: "failed"),
      card(title: "Ship CLI", summary: "Wrote tests"),
    ]
    let text = DailyRecapGenerator.makeCardsText(day: "2026-03-11", cards: cards)
    XCTAssertFalse(text.contains("Processing failed"))
    XCTAssertTrue(text.contains("Ship CLI"))
  }

  func testSummaryEqualToTitleIsNotDuplicated() {
    let text = DailyRecapGenerator.makeCardsText(
      day: "2026-03-11",
      cards: [card(title: "Same", summary: "Same")]
    )
    let occurrences = text.components(separatedBy: "Same").count - 1
    XCTAssertEqual(occurrences, 1)
  }

  func testDistinctSummaryIsIncluded() {
    let text = DailyRecapGenerator.makeCardsText(
      day: "2026-03-11",
      cards: [card(title: "Title", summary: "Longer summary")]
    )
    XCTAssertTrue(text.contains("Longer summary"))
  }

  func testFailedCardsDoNotConsumeTruncationBudget() {
    var cards: [TimelineCard] = []
    for index in 0..<20 {
      cards.append(
        card(
          title: "Processing failed",
          summary: String(repeating: "x", count: 400),
          start: "\(index):00 AM"))
    }
    cards.append(card(title: "Real work", summary: "Kept"))
    let text = DailyRecapGenerator.makeCardsText(
      day: "2026-03-11", cards: cards, maxCharacters: 200)
    XCTAssertTrue(text.contains("Real work"))
    XCTAssertFalse(text.contains("Processing failed"))
    XCTAssertFalse(text.contains("omitted"))
  }

  func testTruncationAddsOmittedNotice() {
    let cards = (0..<30).map { index in
      card(
        title: "Activity \(index) " + String(repeating: "n", count: 40),
        summary: String(repeating: "s", count: 80),
        start: "9:\(String(format: "%02d", index % 60)) AM")
    }
    let text = DailyRecapGenerator.makeCardsText(
      day: "2026-03-11", cards: cards, maxCharacters: 400)
    XCTAssertTrue(text.contains("omitted to stay within the model's context limit"))
  }

  func testAllCardsFitHasNoOmittedNotice() {
    let text = DailyRecapGenerator.makeCardsText(
      day: "2026-03-11",
      cards: [card(title: "One", summary: "Only")]
    )
    XCTAssertFalse(text.contains("omitted"))
  }

  private func card(title: String, summary: String, start: String = "9:00 AM") -> TimelineCard {
    TimelineCard(
      recordId: nil,
      batchId: nil,
      startTimestamp: start,
      endTimestamp: "10:00 AM",
      category: "Work",
      subcategory: "Engineering",
      title: title,
      summary: summary,
      detailedSummary: "",
      day: "2026-03-11",
      distractions: nil,
      videoSummaryURL: nil,
      otherVideoSummaryURLs: nil,
      appSites: nil
    )
  }
}
