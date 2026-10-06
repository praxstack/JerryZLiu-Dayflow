import Foundation
import XCTest
import DayflowCalendar

final class DayflowCalendarTests: XCTestCase {
  func testBeforeFourAMBelongsToPreviousDay() {
    let calendar = losAngelesCalendar()
    let date = makeDate(calendar: calendar, year: 2026, month: 8, day: 12, hour: 3, minute: 30)
    let window = DayflowCalendar.dayWindow(containing: date, calendar: calendar)
    XCTAssertEqual(window.dayKey, "2026-08-11")
    XCTAssertEqual(calendar.component(.hour, from: window.start), 4)
    XCTAssertEqual(calendar.component(.day, from: window.start), 11)
    XCTAssertLessThan(window.start, date)
    XCTAssertGreaterThan(window.end, date)
  }

  func testFourAMStartsNamedDay() {
    let calendar = losAngelesCalendar()
    let date = makeDate(calendar: calendar, year: 2026, month: 8, day: 12, hour: 4, minute: 0)
    let window = DayflowCalendar.dayWindow(containing: date, calendar: calendar)
    XCTAssertEqual(window.dayKey, "2026-08-12")
    XCTAssertEqual(window.start, date)
  }

  func testExplicitDayKeyBuildsFourAMWindow() {
    let calendar = losAngelesCalendar()
    let window = DayflowCalendar.dayWindow(forKey: "2026-08-12", calendar: calendar)
    XCTAssertEqual(window?.dayKey, "2026-08-12")
    let start = makeDate(calendar: calendar, year: 2026, month: 8, day: 12, hour: 4, minute: 0)
    let end = makeDate(calendar: calendar, year: 2026, month: 8, day: 13, hour: 4, minute: 0)
    XCTAssertEqual(window?.start, start)
    XCTAssertEqual(window?.end, end)
  }

  func testExplicitDayKeyRejectsGarbage() {
    XCTAssertNil(DayflowCalendar.dayWindow(forKey: "not-a-date"))
    XCTAssertNil(DayflowCalendar.dayWindow(forKey: ""))
    XCTAssertNil(DayflowCalendar.dayWindow(forKey: "12 August 2026"))
  }

  func testMondayBeforeFourAMBelongsToPreviousWeek() {
    let calendar = DayflowCalendar.mondayGregorian(timeZone: losAngeles)
    // 2026-08-10 is a Monday.
    let mondayEarly = makeDate(calendar: calendar, year: 2026, month: 8, day: 10, hour: 3, minute: 0)
    let window = DayflowCalendar.weekWindow(containing: mondayEarly, calendar: calendar)
    let expectedStart = makeDate(calendar: calendar, year: 2026, month: 8, day: 3, hour: 4, minute: 0)
    XCTAssertEqual(window.start, expectedStart)
    XCTAssertLessThan(window.start, mondayEarly)
    XCTAssertGreaterThan(window.end, mondayEarly)
  }

  func testMondayAtFourAMStartsTheWeek() {
    let calendar = DayflowCalendar.mondayGregorian(timeZone: losAngeles)
    let mondayFour = makeDate(calendar: calendar, year: 2026, month: 8, day: 10, hour: 4, minute: 0)
    let window = DayflowCalendar.weekWindow(containing: mondayFour, calendar: calendar)
    XCTAssertEqual(window.start, mondayFour)
  }

  func testMissingCategoryPreferencesUseDefaults() {
    let categories = DayflowCategories.load(from: nil)
    XCTAssertEqual(categories.map(\.name), ["Work", "Personal", "Distraction", "Idle"])
    XCTAssertEqual(categories.last?.isIdle, true)
    XCTAssertEqual(categories.last?.isSystem, true)
  }

  func testEmptyCategoryJSONUsesDefaults() {
    let categories = DayflowCategories.load(from: Data("[]".utf8))
    XCTAssertEqual(categories.map(\.name), DayflowCategories.defaultCategories.map(\.name))
  }

  func testStoredCategoriesDecodeAndSortByOrder() throws {
    let json = """
      [
        {"name":"Zeta","colorHex":"#111111","order":2,"isSystem":false,"isIdle":false},
        {"name":"Alpha","colorHex":"#222222","order":0,"isSystem":true,"isIdle":true}
      ]
      """
    let categories = DayflowCategories.load(from: Data(json.utf8))
    XCTAssertEqual(categories.map(\.name), ["Alpha", "Zeta"])
    XCTAssertEqual(categories[0].isIdle, true)
    XCTAssertEqual(categories[0].colorHex, "#222222")
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
