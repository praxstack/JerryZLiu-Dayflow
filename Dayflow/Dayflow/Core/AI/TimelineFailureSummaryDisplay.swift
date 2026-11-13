//
//  TimelineFailureSummaryDisplay.swift
//  Dayflow
//
//  Adjusts stored failure summaries for display when automatic retry is no longer
//  eligible, without rewriting timeline_cards rows.
//

import Foundation

enum TimelineFailureSummaryDisplay {
  static let automaticRetrySentence = "Dayflow will try again automatically."
  static let manualRetrySentence = "Use Retry when you're ready."

  static func displayedSummary(
    storedSummary: String,
    automaticRetryStillPossible: Bool
  ) -> String {
    guard !automaticRetryStillPossible else { return storedSummary }
    return replacingAutomaticRetryOffer(in: storedSummary)
  }

  static func replacingAutomaticRetryOffer(in summary: String) -> String {
    if summary.contains(automaticRetrySentence) {
      return summary.replacingOccurrences(
        of: automaticRetrySentence,
        with: manualRetrySentence
      )
    }

    let legacyAutomatic =
      "Dayflow will try again automatically. Your recording is saved."
    if summary.contains(legacyAutomatic) {
      return summary.replacingOccurrences(
        of: legacyAutomatic,
        with: "\(manualRetrySentence) Your recording is saved."
      )
    }

    return summary
  }
}
