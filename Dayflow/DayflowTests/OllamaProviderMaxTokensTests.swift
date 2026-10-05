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

  func testCustomFallbackUsedWhenUnset() {
    let suite = "Dayflow.OllamaProviderMaxTokensTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    XCTAssertEqual(
      OllamaProvider.resolvedMaxOutputTokens(from: defaults, fallback: 2048), 2048)
    XCTAssertEqual(
      OllamaProvider.resolvedMaxOutputTokens(from: defaults, fallback: 65536), 65536)
  }

  func testOverrideWinsOverGeminiAndGemmaFallbacks() {
    let suite = "Dayflow.OllamaProviderMaxTokensTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    defaults.set(32000, forKey: OllamaProvider.maxOutputTokensDefaultsKey)
    XCTAssertEqual(
      OllamaProvider.resolvedMaxOutputTokens(from: defaults, fallback: 2048), 32000)
    XCTAssertEqual(
      OllamaProvider.resolvedMaxOutputTokens(from: defaults, fallback: 8192), 32000)
    XCTAssertEqual(
      OllamaProvider.resolvedMaxOutputTokens(from: defaults, fallback: 65536), 32000)
  }
}
