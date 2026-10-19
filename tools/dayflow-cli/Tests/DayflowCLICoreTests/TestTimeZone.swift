import Foundation
import XCTest

#if canImport(Glibc)
import Glibc
#else
import Darwin
#endif

/// Pins the process time zone for tests that call `dayWindow` / `weekWindow`
/// (they use `Calendar.current`, matching the macOS app).
class DayflowTimeZoneTestCase: XCTestCase {
  private var didSave = false
  private var savedTZ: String?

  func pinTimeZone(_ identifier: String) {
    if !didSave {
      savedTZ = ProcessInfo.processInfo.environment["TZ"]
      didSave = true
    }
    setenv("TZ", identifier, 1)
    tzset()
    resetFoundationTimeZoneCache()
  }

  override func tearDown() {
    if didSave {
      if let savedTZ {
        setenv("TZ", savedTZ, 1)
      } else {
        unsetenv("TZ")
      }
      tzset()
      resetFoundationTimeZoneCache()
      didSave = false
    }
    super.tearDown()
  }

  private func resetFoundationTimeZoneCache() {
    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    NSTimeZone.resetSystemTimeZone()
    #endif
  }
}
