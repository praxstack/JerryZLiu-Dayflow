import XCTest

@testable import Dayflow

final class WeeklyDateRangeBoundaryTests: XCTestCase {
  func testMondayBeforeFourAMBelongsToPreviousWeek() {
    let calendar = Self.mondayCalendar()
    // 2026-03-09 is a Monday.
    let mondayEarly = date(calendar: calendar, year: 2026, month: 3, day: 9, hour: 3, minute: 30)
    let range = WeeklyDateRange.containing(mondayEarly, calendar: calendar)
    let expectedStart = date(calendar: calendar, year: 2026, month: 3, day: 2, hour: 4, minute: 0)
    XCTAssertEqual(range.weekStart, expectedStart)
    XCTAssertLessThan(range.weekStart, mondayEarly)
    XCTAssertGreaterThan(range.weekEnd, mondayEarly)
  }

  func testMondayAtFourAMStartsTheWeek() {
    let calendar = Self.mondayCalendar()
    let mondayFour = date(calendar: calendar, year: 2026, month: 3, day: 9, hour: 4, minute: 0)
    let range = WeeklyDateRange.containing(mondayFour, calendar: calendar)
    XCTAssertEqual(range.weekStart, mondayFour)
  }

  private static func mondayCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = Calendar.current.timeZone
    calendar.firstWeekday = 2
    calendar.minimumDaysInFirstWeek = 4
    return calendar
  }

  private func date(
    calendar: Calendar, year: Int, month: Int, day: Int, hour: Int, minute: Int
  ) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    components.second = 0
    return calendar.date(from: components)!
  }
}
