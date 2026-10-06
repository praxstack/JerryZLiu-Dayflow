import XCTest

@testable import Dayflow

final class DayflowCalendarKernelTests: XCTestCase {
  func testBeforeFourAMBelongsToPreviousDay() {
    let calendar = losAngelesCalendar()
    let date = makeDate(calendar: calendar, year: 2026, month: 8, day: 12, hour: 3, minute: 30)
    let window = DayflowCalendar.dayWindow(containing: date, calendar: calendar)
    XCTAssertEqual(window.dayKey, "2026-08-11")
    XCTAssertEqual(calendar.component(.hour, from: window.start), 4)
  }

  func testExplicitDayKeyBuildsFourAMWindow() {
    let calendar = losAngelesCalendar()
    let window = DayflowCalendar.dayWindow(forKey: "2026-08-12", calendar: calendar)
    let start = makeDate(calendar: calendar, year: 2026, month: 8, day: 12, hour: 4, minute: 0)
    let end = makeDate(calendar: calendar, year: 2026, month: 8, day: 13, hour: 4, minute: 0)
    XCTAssertEqual(window?.start, start)
    XCTAssertEqual(window?.end, end)
  }

  func testMondayBeforeFourAMBelongsToPreviousWeek() {
    let calendar = DayflowCalendar.mondayGregorian(timeZone: losAngeles)
    let mondayEarly = makeDate(calendar: calendar, year: 2026, month: 8, day: 10, hour: 3, minute: 0)
    let window = DayflowCalendar.weekWindow(containing: mondayEarly, calendar: calendar)
    let expectedStart = makeDate(calendar: calendar, year: 2026, month: 8, day: 3, hour: 4, minute: 0)
    XCTAssertEqual(window.start, expectedStart)
  }

  func testAppWrapperAgreesWithKernel() {
    let calendar = Calendar.current
    var components = DateComponents()
    components.year = 2026
    components.month = 8
    components.day = 12
    components.hour = 3
    components.minute = 30
    let date = calendar.date(from: components)!
    let info = date.getDayInfoFor4AMBoundary()
    let window = DayflowCalendar.dayWindow(containing: date, calendar: calendar)
    XCTAssertEqual(info.dayString, window.dayKey)
    XCTAssertEqual(info.startOfDay, window.start)
    XCTAssertEqual(info.endOfDay, window.end)
  }

  func testDefaultCategoriesMatchCLIList() {
    XCTAssertEqual(
      DayflowCategories.defaultCategories.map(\.name),
      ["Work", "Personal", "Distraction", "Idle"])
  }

  func testStoredCategoriesJSONDecode() {
    let json = Data(#"[{"name":"Focus","colorHex":"#000000","order":1}]"#.utf8)
    let categories = DayflowCategories.load(from: json)
    XCTAssertEqual(categories.map(\.name), ["Focus"])
  }

  private var losAngeles: TimeZone {
    TimeZone(identifier: "America/Los_Angeles")!
  }

  private func losAngelesCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = losAngeles
    return calendar
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
}
