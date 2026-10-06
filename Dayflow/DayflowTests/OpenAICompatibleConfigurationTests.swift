import XCTest

@testable import Dayflow

/// macOS-app compile check plus Ollama transport tests. The exhaustive
/// configuration / screenshot-budget suite lives in
/// `tools/openai-compatible-kernel` and is what Linux CI runs.
final class OpenAICompatibleConfigurationTests: XCTestCase {
  func testKernelTypesAreLinkedIntoTheAppModule() {
    XCTAssertEqual(OpenAICompatibleScreenshotBudget.defaultLimit, 15)
    XCTAssertEqual(OpenAICompatibleScreenshotBudget.clamp(0), 1)
    XCTAssertEqual(OpenAICompatibleScreenshotBudget.clamp(99), 15)
    XCTAssertEqual(
      OpenAICompatibleScreenshotBudget.select(Array(0..<31), limit: 8).last, 30)
    XCTAssertEqual(
      OpenAICompatibleConfiguration.openRouter(modelID: "openai/example-model")
        .chatCompletionsURL?.absoluteString,
      "https://openrouter.ai/api/v1/chat/completions"
    )
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
}
