import Foundation

enum LocalEndpointUtilities {
  /// Builds a chat-completions endpoint URL from a user-provided base URL.
  /// Delegates to the OpenAI-compatible kernel so Linux tests cover the same path.
  static func chatCompletionsURL(baseURL: String) -> URL? {
    OpenAICompatibleEndpoint.chatCompletionsURL(baseURL: baseURL)
  }
}
