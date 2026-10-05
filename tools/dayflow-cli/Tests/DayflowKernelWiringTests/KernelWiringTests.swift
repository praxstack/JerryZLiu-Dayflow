import Foundation
import XCTest
import DayflowCalendar

/// Proves the CLI package links the shared kernel (plan 002 option B).
/// Folding the CLI into the Xcode app target remains option A / macOS-only.
final class KernelWiringTests: XCTestCase {
  func testCLIPackageLinksDayflowCalendar() {
    XCTAssertEqual(DayflowCalendar.dayStartHour, 4)
  }

  func testDayWindowAgreesWithKernelAPI() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
    let date = calendar.date(
      from: DateComponents(year: 2026, month: 8, day: 12, hour: 3, minute: 30, second: 0))!
    let window = DayflowCalendar.dayWindow(containing: date, calendar: calendar)
    XCTAssertEqual(window.dayKey, "2026-08-11")
  }
}
