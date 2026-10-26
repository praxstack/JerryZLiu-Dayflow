import Foundation
import XCTest
import DayflowCalendar

/// Proves the CLI SwiftPM package still links the shared kernel on Linux/CI.
/// The macOS app graph also compiles these sources as the `dayflow-cli` tool.
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
