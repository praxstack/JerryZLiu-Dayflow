import XCTest

@testable import Dayflow

final class StorageDateHelpersTests: XCTestCase {
  func testBeforeFourAMBelongsToPreviousDay() {
    let calendar = Calendar.current
    let date = date(calendar: calendar, year: 2026, month: 3, day: 11, hour: 3, minute: 30)
    let expectedStart = date(calendar: calendar, year: 2026, month: 3, day: 10, hour: 4, minute: 0)
    let expectedEnd = date(calendar: calendar, year: 2026, month: 3, day: 11, hour: 4, minute: 0)
    let info = date.getDayInfoFor4AMBoundary()
    XCTAssertEqual(info.dayString, DateFormatter.yyyyMMdd.string(from: expectedStart))
    XCTAssertEqual(info.startOfDay, expectedStart)
    XCTAssertEqual(info.endOfDay, expectedEnd)
    XCTAssertLessThan(info.startOfDay, date)
    XCTAssertGreaterThan(info.endOfDay, date)
  }

  func testFourAMStartsTheNamedDay() {
    let calendar = Calendar.current
    let date = date(calendar: calendar, year: 2026, month: 3, day: 11, hour: 4, minute: 0)
    let info = date.getDayInfoFor4AMBoundary()
    XCTAssertEqual(info.dayString, DateFormatter.yyyyMMdd.string(from: date))
    XCTAssertEqual(info.startOfDay, date)
  }

  func testAfternoonStaysOnTheSameDayflowDay() {
    let calendar = Calendar.current
    let date = date(calendar: calendar, year: 2026, month: 3, day: 11, hour: 15, minute: 45)
    let expectedStart = date(calendar: calendar, year: 2026, month: 3, day: 11, hour: 4, minute: 0)
    let info = date.getDayInfoFor4AMBoundary()
    XCTAssertEqual(info.dayString, DateFormatter.yyyyMMdd.string(from: expectedStart))
  }

  private func date(
    calendar: Calendar, year: Int, month: Int, day: Int, hour: Int, minute: Int
  ) -> Date {
    var components = DateComponents()
    components.timeZone = calendar.timeZone
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    components.second = 0
    return calendar.date(from: components)!
  }
}
