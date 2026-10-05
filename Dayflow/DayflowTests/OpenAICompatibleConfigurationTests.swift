import XCTest

@testable import Dayflow

final class OpenAICompatibleConfigurationTests: XCTestCase {
  private final class IgnoringUserDefaults: UserDefaults {
    var ignoredWriteKeys: Set<String> = []

    override func set(_ value: Any?, forKey defaultName: String) {
      guard !ignoredWriteKeys.contains(defaultName) else { return }
      super.set(value, forKey: defaultName)
    }
  }

  func testOpenRouterPresetBuildsChatCompletionsURL() {
    let configuration = OpenAICompatibleConfiguration.openRouter(
      modelID: "  openai/example-model  ")

    XCTAssertEqual(configuration.preset, .openRouter)
    XCTAssertEqual(configuration.baseURL, "https://openrouter.ai/api/v1")
    XCTAssertEqual(configuration.modelID, "openai/example-model")
    XCTAssertEqual(
      configuration.maxImagesPerRequest, OpenAICompatibleScreenshotBudget.defaultLimit)
    XCTAssertEqual(
      configuration.chatCompletionsURL?.absoluteString,
      "https://openrouter.ai/api/v1/chat/completions"
    )
    XCTAssertTrue(configuration.isComplete)
  }

  func testConfigurationPreferencesRoundTripInIsolatedDefaults() throws {
    let suiteName = "OpenAICompatibleConfigurationTests.\(UUID().uuidString)"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let configuration = OpenAICompatibleConfiguration(
      preset: .custom,
      baseURL: "https://example.com/v1/chat/completions",
      modelID: "vision-model"
    )

    XCTAssertTrue(OpenAICompatiblePreferences.save(configuration, to: defaults))
    XCTAssertEqual(OpenAICompatiblePreferences.load(from: defaults), configuration)

    OpenAICompatiblePreferences.reset(in: defaults)
    XCTAssertNil(OpenAICompatiblePreferences.load(from: defaults))
    XCTAssertEqual(OpenAICompatiblePreferences.keychainProvider, "openai_compatible")
    XCTAssertEqual(configuration.maxImagesPerRequest, 15)
  }

  func testLegacyConfigurationJSONDefaultsMaxImagesToFifteen() throws {
    let payload = """
      {"preset":"custom","baseURL":"https://gateway.example/v1","modelID":"vision"}
      """.data(using: .utf8)!
    let decoded = try JSONDecoder().decode(OpenAICompatibleConfiguration.self, from: payload)
    XCTAssertEqual(decoded.maxImagesPerRequest, 15)
    XCTAssertEqual(decoded.preset, .custom)
    XCTAssertEqual(decoded.baseURL, "https://gateway.example/v1")
  }

  func testMaxImagesPerRequestClampsAndRoundTrips() throws {
    let suiteName = "OpenAICompatibleConfigurationTests.\(UUID().uuidString)"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let eight = OpenAICompatibleConfiguration(
      preset: .custom,
      baseURL: "https://gateway.example/v1",
      modelID: "vision",
      maxImagesPerRequest: 8
    )
    XCTAssertEqual(eight.maxImagesPerRequest, 8)
    XCTAssertTrue(OpenAICompatiblePreferences.save(eight, to: defaults))
    XCTAssertEqual(OpenAICompatiblePreferences.load(from: defaults)?.maxImagesPerRequest, 8)

    XCTAssertEqual(
      OpenAICompatibleConfiguration(
        preset: .custom, baseURL: "https://gateway.example/v1", modelID: "vision",
        maxImagesPerRequest: 0
      ).maxImagesPerRequest, 1)
    XCTAssertEqual(
      OpenAICompatibleConfiguration(
        preset: .custom, baseURL: "https://gateway.example/v1", modelID: "vision",
        maxImagesPerRequest: 99
      ).maxImagesPerRequest, 15)
  }

  func testScreenshotBudgetSamplesEndpointsAndHonorsLimit() {
    let frames = Array(0..<31)
    XCTAssertEqual(OpenAICompatibleScreenshotBudget.select(frames, limit: 15).count, 15)
    XCTAssertEqual(OpenAICompatibleScreenshotBudget.select(frames, limit: 15).first, 0)
    XCTAssertEqual(OpenAICompatibleScreenshotBudget.select(frames, limit: 15).last, 30)
    XCTAssertEqual(OpenAICompatibleScreenshotBudget.select(frames, limit: 8).count, 8)
    XCTAssertEqual(OpenAICompatibleScreenshotBudget.select(frames, limit: 8).last, 30)
    XCTAssertEqual(OpenAICompatibleScreenshotBudget.select(Array(0..<5), limit: 15), [0, 1, 2, 3, 4])
    XCTAssertEqual(OpenAICompatibleScreenshotBudget.select([42], limit: 8), [42])
    XCTAssertEqual(OpenAICompatibleScreenshotBudget.select([Int](), limit: 8), [])
  }

  func testHTTPErrorFormatterPrefersGatewayErrorMessage() throws {
    let nested = try JSONSerialization.data(withJSONObject: [
      "error": ["message": "max 8 images per request", "type": "invalid_request_error"]
    ])
    XCTAssertEqual(
      OpenAICompatibleHTTPErrorFormatter.userMessage(statusCode: 400, body: nested),
      "HTTP 400: max 8 images per request")

    let topLevel = try JSONSerialization.data(withJSONObject: [
      "message": "too many attachments"
    ])
    XCTAssertEqual(
      OpenAICompatibleHTTPErrorFormatter.userMessage(statusCode: 413, body: topLevel),
      "HTTP 413: too many attachments")

    XCTAssertEqual(
      OpenAICompatibleHTTPErrorFormatter.userMessage(
        statusCode: 500, body: Data("plain failure".utf8)),
      "HTTP 500: plain failure")
  }

  func testInjectedRuntimeBuildsIndependentBearerRequest() throws {
    let storedConfiguration = OpenAICompatibleConfiguration(
      preset: .custom,
      baseURL: "https://example.com/api/v1",
      modelID: "remote-vision-model"
    )
    let runtimeConfiguration = OpenAICompatibleRuntimeConfiguration(
      configuration: storedConfiguration,
      bearerToken: "  remote-secret  "
    )
    XCTAssertEqual(runtimeConfiguration.maxImagesPerRequest, 15)
    let provider = OllamaProvider(openAICompatible: runtimeConfiguration)
    let chatRequest = OllamaProvider.ChatRequest(
      model: provider.savedModelId,
      messages: [
        OllamaProvider.ChatMessage(
          role: "user",
          content: [
            OllamaProvider.MessageContent(type: "text", text: "hello", image_url: nil)
          ]
        )
      ],
      temperature: 0.2,
      max_tokens: 20,
      stream: false
    )

    let request = try provider.makeChatURLRequest(chatRequest)

    XCTAssertEqual(request.url?.absoluteString, "https://example.com/api/v1/chat/completions")
    XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer remote-secret")
    XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
    XCTAssertEqual(provider.savedModelId, "remote-vision-model")
    XCTAssertEqual(provider.localEngine, "openai_compatible")
    XCTAssertFalse(provider.isLMStudio)
    XCTAssertFalse(provider.isCustomEngine)
    XCTAssertNil(provider.customAPIKey)

    let body = try XCTUnwrap(request.httpBody)
    let decoded = try JSONDecoder().decode(OllamaProvider.ChatRequest.self, from: body)
    XCTAssertEqual(decoded.model, "remote-vision-model")
  }

  func testInjectedRuntimeOmitsEmptyBearerToken() throws {
    let configuration = OpenAICompatibleConfiguration(
      preset: .custom,
      baseURL: "https://example.com",
      modelID: "model"
    )
    let runtimeConfiguration = OpenAICompatibleRuntimeConfiguration(
      configuration: configuration,
      bearerToken: "   "
    )
    let provider = OllamaProvider(openAICompatible: runtimeConfiguration)
    let chatRequest = OllamaProvider.ChatRequest(
      model: "model",
      messages: [],
      temperature: 0.7,
      max_tokens: 10,
      stream: false
    )

    let request = try provider.makeChatURLRequest(chatRequest)

    XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
  }

  func testFailedConfigurationWritePreservesPreviousValue() throws {
    let suiteName = "OpenAICompatibleConfigurationTests.\(UUID().uuidString)"
    let defaults = try XCTUnwrap(IgnoringUserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let previous = OpenAICompatibleConfiguration.openRouter(modelID: "previous-model")
    let replacement = OpenAICompatibleConfiguration(
      preset: .custom,
      baseURL: "https://replacement.example/v1",
      modelID: "replacement-model"
    )
    XCTAssertTrue(OpenAICompatiblePreferences.save(previous, to: defaults))
    defaults.ignoredWriteKeys = ["llmOpenAICompatibleConfigurationV1"]

    XCTAssertFalse(OpenAICompatiblePreferences.save(replacement, to: defaults))
    XCTAssertEqual(OpenAICompatiblePreferences.load(from: defaults), previous)
  }
}
