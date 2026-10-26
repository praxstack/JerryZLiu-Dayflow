import Foundation

struct WeeklyDateRange: Equatable, Sendable {
  let weekStart: Date
  let weekEnd: Date

  /// Weekday, month and day in the current locale's order (e.g. "Monday, September 8" or "8. September, Montag").
  private static let titleDayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.setLocalizedDateFormatFromTemplate("EEEEMMMMd")
    return formatter
  }()

  static func containing(_ date: Date, calendar: Calendar = Self.calendar) -> WeeklyDateRange {
    let window = DayflowCalendar.weekWindow(containing: date, calendar: calendar)
    return WeeklyDateRange(weekStart: window.start, weekEnd: window.end)
  }

  func shifted(byWeeks weeks: Int, calendar: Calendar = Self.calendar) -> WeeklyDateRange {
    let shiftedStart = calendar.date(byAdding: .day, value: weeks * 7, to: weekStart) ?? weekStart
    let shiftedEnd = calendar.date(byAdding: .day, value: 7, to: shiftedStart) ?? shiftedStart
    return WeeklyDateRange(weekStart: shiftedStart, weekEnd: shiftedEnd)
  }

  var canNavigateForward: Bool {
    weekStart < Self.containing(Date()).weekStart
  }

  var title: String {
    let displayWeekEnd = Self.calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
    let startText = Self.titleDayFormatter.string(from: weekStart)
    let endText = Self.titleDayFormatter.string(from: displayWeekEnd)
    return String(localized: "\(startText) - \(endText)")
  }

  private static let calendar: Calendar = DayflowCalendar.mondayGregorian()
}
