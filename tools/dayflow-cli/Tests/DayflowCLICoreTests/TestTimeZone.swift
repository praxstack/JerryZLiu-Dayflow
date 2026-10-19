import Foundation
import XCTest

/// Pins the process time zone for tests that call `dayWindow` / `weekWindow`
/// (they use `Calendar.current`, matching the macOS app).
class DayflowTimeZoneTestCase: XCTestCase {
  private var savedTimeZoneIdentifier: String?

  func pinTimeZone(_ identifier: String) {
    savedTimeZoneIdentifier = TimeZone.current.identifier
    setenv("TZ", identifier, 1)
    tzset()
  }

  override func tearDown() {
    if let savedTimeZoneIdentifier {
      setenv("TZ", savedTimeZoneIdentifier, 1)
      tzset()
    } else {
      unsetenv("TZ")
      tzset()
    }
    super.tearDown()
  }
}
