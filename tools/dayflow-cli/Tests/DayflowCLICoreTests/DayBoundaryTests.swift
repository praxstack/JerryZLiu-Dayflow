import Foundation
import XCTest
import DayflowCLICore

final class DayBoundaryTests: XCTestCase {
  func testBeforeFourAMBelongsToPreviousDay() {
    let calendar = Calendar.current
    let date = makeDate(calendar: calendar, year: 2026, month: 3, day: 11, hour: 3, minute: 30)
    let window = dayWindow(containing: date)
    XCTAssertEqual(window.dayKey, expectedKey(calendar: calendar, year: 2026, month: 3, day: 10))
    XCTAssertEqual(calendar.component(.hour, from: window.start), 4)
    XCTAssertLessThan(window.start, date)
    XCTAssertGreaterThan(window.end, date)
  }

  func testFourAMStartsNamedDay() {
    let calendar = Calendar.current
    let date = makeDate(calendar: calendar, year: 2026, month: 3, day: 11, hour: 4, minute: 0)
    let window = dayWindow(containing: date)
    XCTAssertEqual(window.dayKey, expectedKey(calendar: calendar, year: 2026, month: 3, day: 11))
  }

  func testForKeyRejectsGarbage() {
    XCTAssertNil(dayWindow(forKey: "not-a-date"))
    XCTAssertNil(dayWindow(forKey: ""))
    XCTAssertNil(dayWindow(forKey: "11 March 2026"))
  }

  func testForKeyBuildsFourAMWindow() {
    guard let window = dayWindow(forKey: "2026-03-11") else {
      XCTFail("expected a window")
      return
    }
    XCTAssertEqual(window.dayKey, "2026-03-11")
    XCTAssertEqual(Calendar.current.component(.hour, from: window.start), 4)
    let hours = window.end.timeIntervalSince(window.start) / 3600
    XCTAssertEqual(hours, 24, accuracy: 0.01)
  }

  func testFormatDuration() {
    XCTAssertEqual(formatDuration(minutes: 5), "5m")
    XCTAssertEqual(formatDuration(minutes: 60), "1h")
    XCTAssertEqual(formatDuration(minutes: 75), "1h 15m")
  }

  private func makeDate(
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

  private func expectedKey(calendar: Calendar, year: Int, month: Int, day: Int) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = calendar.timeZone
    return formatter.string(
      from: makeDate(calendar: calendar, year: year, month: month, day: day, hour: 4, minute: 0))
  }
}
