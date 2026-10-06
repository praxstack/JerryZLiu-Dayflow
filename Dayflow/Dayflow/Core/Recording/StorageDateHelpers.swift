//
//  StorageManager.swift
//  Dayflow
//

import Foundation
import GRDB
import Sentry

extension DateFormatter {
  static let yyyyMMdd: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = Calendar.current.timeZone
    return formatter
  }()
}

extension Date {
  /// Calculates the "day" based on a 4 AM start time.
  /// Returns the date string (YYYY-MM-DD) and the Date objects for the start and end of that day.
  func getDayInfoFor4AMBoundary() -> (dayString: String, startOfDay: Date, endOfDay: Date) {
    let window = DayflowCalendar.dayWindow(containing: self)
    return (window.dayKey, window.start, window.end)
  }
}
