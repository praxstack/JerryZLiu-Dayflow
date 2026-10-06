import Foundation

public enum OpenAICompatiblePreset: String, Codable, CaseIterable, Sendable {
  case openRouter = "openrouter"
  case custom
}

/// Caps how many screenshots a single OpenAI-compatible transcription request may attach.
public enum OpenAICompatibleScreenshotBudget {
  public static let defaultLimit = 15
  public static let minimumLimit = 1
  public static let maximumLimit = 15

  public static func clamp(_ value: Int) -> Int {
    min(maximumLimit, max(minimumLimit, value))
  }

  /// Evenly samples `items` down to `limit`, always keeping the first and last when possible.
  public static func select<T>(_ items: [T], limit: Int) -> [T] {
    guard !items.isEmpty else { return [] }
    let count = min(clamp(limit), items.count)
    if count == 1 { return [items[0]] }
    return (0..<count).map { index in
      items[index * (items.count - 1) / (count - 1)]
    }
  }
}

/// Pulls a gateway's `error.message` out of an HTTP body so setup tests can show it.
public enum OpenAICompatibleHTTPErrorFormatter {
  public static func userMessage(statusCode: Int, body: Data) -> String {
    if let extracted = extractMessage(from: body), !extracted.isEmpty {
      return "HTTP \(statusCode): \(extracted)"
    }
    let text = String(data: body, encoding: .utf8)?
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return text.isEmpty ? "HTTP \(statusCode)" : "HTTP \(statusCode): \(text)"
  }

  public static func extractMessage(from body: Data) -> String? {
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

/// Builds a chat-completions endpoint URL from a user-provided base URL.
/// The base may already include `/v1` (e.g., https://openrouter.ai/api/v1) or a full `/v1/chat/completions` path.
public enum OpenAICompatibleEndpoint {
  public static func chatCompletionsURL(baseURL: String) -> URL? {
    let trimmed = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    guard var components = URLComponents(string: trimmed) else { return nil }

    var normalizedPath = sanitize(components.path)
    let targetPath = "/v1/chat/completions"

    if normalizedPath.isEmpty {
      normalizedPath = targetPath
    } else if normalizedPath.hasSuffix(targetPath) {
      // already points to /v1/chat/completions – keep as-is
    } else if normalizedPath.hasSuffix("/v1") {
      normalizedPath.append(contentsOf: "/chat/completions")
    } else {
      if normalizedPath == "/" {
        normalizedPath = targetPath
      } else {
        normalizedPath.append(contentsOf: targetPath)
      }
    }

    if !normalizedPath.hasPrefix("/") {
      normalizedPath = "/" + normalizedPath
    }

    components.path = normalizedPath
    return components.url
  }

  private static func sanitize(_ path: String) -> String {
    guard !path.isEmpty else { return "" }
    var normalized = path
    while normalized.contains("//") {
      normalized = normalized.replacingOccurrences(of: "//", with: "/")
    }
    while normalized.count > 1 && normalized.hasSuffix("/") {
      normalized.removeLast()
    }
    return normalized
  }
}

public struct OpenAICompatibleConfiguration: Codable, Equatable, Sendable {
  public static let openRouterBaseURL = "https://openrouter.ai/api/v1"

  public let preset: OpenAICompatiblePreset
  public let baseURL: String
  public let modelID: String
  public let maxImagesPerRequest: Int

  public init(
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

  public static func openRouter(modelID: String = "") -> OpenAICompatibleConfiguration {
    OpenAICompatibleConfiguration(
      preset: .openRouter,
      baseURL: openRouterBaseURL,
      modelID: modelID
    )
  }

  public var chatCompletionsURL: URL? {
    OpenAICompatibleEndpoint.chatCompletionsURL(baseURL: baseURL)
  }

  public var isComplete: Bool {
    !baseURL.isEmpty && !modelID.isEmpty && chatCompletionsURL != nil
  }

  enum CodingKeys: String, CodingKey {
    case preset
    case baseURL
    case modelID
    case maxImagesPerRequest
  }

  public init(from decoder: Decoder) throws {
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

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(preset, forKey: .preset)
    try container.encode(baseURL, forKey: .baseURL)
    try container.encode(modelID, forKey: .modelID)
    try container.encode(maxImagesPerRequest, forKey: .maxImagesPerRequest)
  }
}

public enum OpenAICompatiblePreferences {
  public static let keychainProvider = "openai_compatible"
  public static let configurationKey = "llmOpenAICompatibleConfigurationV1"

  public static func load(from defaults: UserDefaults = .standard) -> OpenAICompatibleConfiguration? {
    guard let data = defaults.data(forKey: configurationKey) else { return nil }
    return try? JSONDecoder().decode(OpenAICompatibleConfiguration.self, from: data)
  }

  @discardableResult
  public static func save(
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

  public static func reset(in defaults: UserDefaults = .standard) {
    defaults.removeObject(forKey: configurationKey)
  }
}

public struct OpenAICompatibleRuntimeConfiguration: Sendable {
  public let endpoint: String
  public let modelID: String
  public let bearerToken: String?
  public let analyticsProvider: String
  public let maxImagesPerRequest: Int

  public init(
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
