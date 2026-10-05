import Foundation

enum OpenAICompatiblePreset: String, Codable, CaseIterable {
  case openRouter = "openrouter"
  case custom
}

/// Caps how many screenshots a single OpenAI-compatible transcription request may attach.
enum OpenAICompatibleScreenshotBudget {
  static let defaultLimit = 15
  static let minimumLimit = 1
  static let maximumLimit = 15

  static func clamp(_ value: Int) -> Int {
    min(maximumLimit, max(minimumLimit, value))
  }

  /// Evenly samples `items` down to `limit`, always keeping the first and last when possible.
  static func select<T>(_ items: [T], limit: Int) -> [T] {
    guard !items.isEmpty else { return [] }
    let count = min(clamp(limit), items.count)
    if count == 1 { return [items[0]] }
    return (0..<count).map { index in
      items[index * (items.count - 1) / (count - 1)]
    }
  }
}

/// Pulls a gateway's `error.message` out of an HTTP body so setup tests can show it.
enum OpenAICompatibleHTTPErrorFormatter {
  static func userMessage(statusCode: Int, body: Data) -> String {
    if let extracted = extractMessage(from: body), !extracted.isEmpty {
      return "HTTP \(statusCode): \(extracted)"
    }
    let text = String(data: body, encoding: .utf8)?
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return text.isEmpty ? "HTTP \(statusCode)" : "HTTP \(statusCode): \(text)"
  }

  static func extractMessage(from body: Data) -> String? {
    guard let object = try? JSONSerialization.jsonObject(with: body) else { return nil }
    return extractMessage(from: object)
  }

  private static func extractMessage(from object: Any) -> String? {
    guard let dict = object as? [String: Any] else { return nil }
    if let error = dict["error"] {
      if let nested = error as? [String: Any], let message = nested["message"] as? String {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
      }
      if let message = error as? String {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
      }
    }
    if let message = dict["message"] as? String {
      let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
      return trimmed.isEmpty ? nil : trimmed
    }
    return nil
  }
}

struct OpenAICompatibleConfiguration: Codable, Equatable {
  static let openRouterBaseURL = "https://openrouter.ai/api/v1"

  let preset: OpenAICompatiblePreset
  let baseURL: String
  let modelID: String
  let maxImagesPerRequest: Int

  init(
    preset: OpenAICompatiblePreset,
    baseURL: String,
    modelID: String,
    maxImagesPerRequest: Int = OpenAICompatibleScreenshotBudget.defaultLimit
  ) {
    self.preset = preset
    self.baseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
    self.modelID = modelID.trimmingCharacters(in: .whitespacesAndNewlines)
    self.maxImagesPerRequest = OpenAICompatibleScreenshotBudget.clamp(maxImagesPerRequest)
  }

  static func openRouter(modelID: String = "") -> OpenAICompatibleConfiguration {
    OpenAICompatibleConfiguration(
      preset: .openRouter,
      baseURL: openRouterBaseURL,
      modelID: modelID
    )
  }

  var chatCompletionsURL: URL? {
    LocalEndpointUtilities.chatCompletionsURL(baseURL: baseURL)
  }

  var isComplete: Bool {
    !baseURL.isEmpty && !modelID.isEmpty && chatCompletionsURL != nil
  }

  enum CodingKeys: String, CodingKey {
    case preset
    case baseURL
    case modelID
    case maxImagesPerRequest
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let preset = try container.decode(OpenAICompatiblePreset.self, forKey: .preset)
    let baseURL = try container.decode(String.self, forKey: .baseURL)
    let modelID = try container.decode(String.self, forKey: .modelID)
    let rawMaxImages =
      try container.decodeIfPresent(Int.self, forKey: .maxImagesPerRequest)
      ?? OpenAICompatibleScreenshotBudget.defaultLimit
    self.init(
      preset: preset,
      baseURL: baseURL,
      modelID: modelID,
      maxImagesPerRequest: rawMaxImages
    )
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(preset, forKey: .preset)
    try container.encode(baseURL, forKey: .baseURL)
    try container.encode(modelID, forKey: .modelID)
    try container.encode(maxImagesPerRequest, forKey: .maxImagesPerRequest)
  }
}

enum OpenAICompatiblePreferences {
  static let keychainProvider = "openai_compatible"
  private static let configurationKey = "llmOpenAICompatibleConfigurationV1"

  static func load(from defaults: UserDefaults = .standard) -> OpenAICompatibleConfiguration? {
    guard let data = defaults.data(forKey: configurationKey) else { return nil }
    return try? JSONDecoder().decode(OpenAICompatibleConfiguration.self, from: data)
  }

  @discardableResult
  static func save(
    _ configuration: OpenAICompatibleConfiguration,
    to defaults: UserDefaults = .standard
  ) -> Bool {
    guard let data = try? JSONEncoder().encode(configuration) else { return false }
    let previousValue = defaults.object(forKey: configurationKey)
    defaults.set(data, forKey: configurationKey)
    guard load(from: defaults) == configuration else {
      if let previousValue {
        defaults.set(previousValue, forKey: configurationKey)
      } else {
        defaults.removeObject(forKey: configurationKey)
      }
      return false
    }
    return true
  }

  static func reset(in defaults: UserDefaults = .standard) {
    defaults.removeObject(forKey: configurationKey)
  }
}

struct OpenAICompatibleRuntimeConfiguration: Sendable {
  let endpoint: String
  let modelID: String
  let bearerToken: String?
  let analyticsProvider: String
  let maxImagesPerRequest: Int

  init(
    configuration: OpenAICompatibleConfiguration,
    bearerToken: String?,
    analyticsProvider: String = OpenAICompatiblePreferences.keychainProvider
  ) {
    endpoint = configuration.baseURL
    modelID = configuration.modelID
    maxImagesPerRequest = configuration.maxImagesPerRequest

    let trimmedToken = bearerToken?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    self.bearerToken = trimmedToken.isEmpty ? nil : trimmedToken

    let trimmedProvider = analyticsProvider.trimmingCharacters(in: .whitespacesAndNewlines)
    self.analyticsProvider =
      trimmedProvider.isEmpty
      ? OpenAICompatiblePreferences.keychainProvider
      : trimmedProvider
  }
}
