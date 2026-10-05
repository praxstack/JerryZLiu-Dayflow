import XCTest

@testable import Dayflow

final class StorageDateHelpersTests: XCTestCase {
  func testBeforeFourAMBelongsToPreviousDay() {
    let calendar = Calendar.current
    let date = date(calendar: calendar, year: 2026, month: 3, day: 11, hour: 3, minute: 30)
    let info = date.getDayInfoFor4AMBoundary()
    XCTAssertEqual(info.dayString, expectedDayString(calendar: calendar, year: 2026, month: 3, day: 10))
    XCTAssertEqual(calendar.component(.hour, from: info.startOfDay), 4)
    XCTAssertLessThan(info.startOfDay, date)
    XCTAssertGreaterThan(info.endOfDay, date)
  }

  func testFourAMStartsTheNamedDay() {
    let calendar = Calendar.current
    let date = date(calendar: calendar, year: 2026, month: 3, day: 11, hour: 4, minute: 0)
    let info = date.getDayInfoFor4AMBoundary()
    XCTAssertEqual(info.dayString, expectedDayString(calendar: calendar, year: 2026, month: 3, day: 11))
    XCTAssertEqual(info.startOfDay, date)
  }

  func testAfternoonStaysOnTheSameDayflowDay() {
    let calendar = Calendar.current
    let date = date(calendar: calendar, year: 2026, month: 3, day: 11, hour: 15, minute: 45)
    let info = date.getDayInfoFor4AMBoundary()
    XCTAssertEqual(info.dayString, expectedDayString(calendar: calendar, year: 2026, month: 3, day: 11))
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

  private func expectedDayString(calendar: Calendar, year: Int, month: Int, day: Int) -> String {
    let start = date(calendar: calendar, year: year, month: month, day: day, hour: 4, minute: 0)
    return DateFormatter.yyyyMMdd.string(from: start)
  }
}
