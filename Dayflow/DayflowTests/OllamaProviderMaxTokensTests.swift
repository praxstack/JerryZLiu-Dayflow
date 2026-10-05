import XCTest

@testable import Dayflow

final class OllamaProviderMaxTokensTests: XCTestCase {
  func testMissingOverrideUsesDefault4000() {
    let suite = "Dayflow.OllamaProviderMaxTokensTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    XCTAssertEqual(OllamaProvider.resolvedMaxOutputTokens(from: defaults), 4000)
  }

  func testZeroIsTreatedAsUnset() {
    let suite = "Dayflow.OllamaProviderMaxTokensTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    defaults.set(0, forKey: OllamaProvider.maxOutputTokensDefaultsKey)
    XCTAssertEqual(OllamaProvider.resolvedMaxOutputTokens(from: defaults), 4000)
  }

  func testPositiveOverrideWins() {
    let suite = "Dayflow.OllamaProviderMaxTokensTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    defaults.set(32000, forKey: OllamaProvider.maxOutputTokensDefaultsKey)
    XCTAssertEqual(OllamaProvider.resolvedMaxOutputTokens(from: defaults), 32000)
  }

  func testNegativeOverrideIsIgnored() {
    let suite = "Dayflow.OllamaProviderMaxTokensTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    defaults.set(-1, forKey: OllamaProvider.maxOutputTokensDefaultsKey)
    XCTAssertEqual(OllamaProvider.resolvedMaxOutputTokens(from: defaults), 4000)
  }
}
