import Foundation
#if canImport(OpenAI)
import OpenAI
#endif

enum LLMServiceError: Error, Equatable {
    case missingAPIKey
    case emptyInput
    case emptyResponse
    case missingFixedGrammarTag
    case libraryUnavailable
}

final class LLMService {
#if canImport(OpenAI)
    private let clientLock = NSLock()
    private var cachedClient: OpenAI?
    private var cachedKey: String?
#endif

    func runGrammarTask(input: String, apiKey: String) async throws -> String {
        let trimmedInput = input.trimmed
        guard !trimmedInput.isEmpty else { throw LLMServiceError.emptyInput }
        guard !apiKey.trimmed.isEmpty else { throw LLMServiceError.missingAPIKey }

#if canImport(OpenAI)
        let client = configuredClient(apiKey: apiKey)
        let systemPrompt = """
        You are a meticulous copy editor. Fix grammar, spelling, and punctuation in the provided text while preserving original tone and meaning. Respond only with XML containing a single <fixed_grammar> element, and place the corrected passage inside it without additional commentary.
        """

        let userPrompt = """
        <text_to_edit>
        \(trimmedInput)
        </text_to_edit>
        """

        // Build messages using the non-optional content API
        let messages: [ChatQuery.ChatCompletionMessageParam] = [
            .system(.init(content: .textContent(systemPrompt))),
            .user(.init(content: .string(userPrompt)))
        ]

        // Use a supported model identifier
        let query = ChatQuery(
            messages: messages,
            model: .gpt5
        )

        // Execute chat and extract the first textual content piece
        let response = try await client.chats(query: query)

        guard let rawContent = response
            .choices
            .first?
            .message
            .content?
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
            !rawContent.isEmpty else {
            throw LLMServiceError.emptyResponse
        }

        guard let fixed = extractFixedGrammar(from: rawContent)?.trimmed, !fixed.isEmpty else {
            throw LLMServiceError.missingFixedGrammarTag
        }

        return fixed
#else
        throw LLMServiceError.libraryUnavailable
#endif
    }

    func runResumeTask(input: String, apiKey: String) async throws -> String {
        // resume support to be implemented
        return input
    }

    private func extractFixedGrammar(from content: String) -> String? {
        guard
            let startRange = content.range(of: "<fixed_grammar>", options: [.caseInsensitive]),
            let endRange = content.range(of: "</fixed_grammar>", options: [.caseInsensitive])
        else {
            return nil
        }

        let innerRange = startRange.upperBound..<endRange.lowerBound
        return String(content[innerRange])
    }

#if canImport(OpenAI)
    private func configuredClient(apiKey: String) -> OpenAI {
        clientLock.lock()
        defer { clientLock.unlock() }

        if cachedKey == apiKey, let cachedClient {
            return cachedClient
        }

        let client = OpenAI(apiToken: apiKey)
        cachedClient = client
        cachedKey = apiKey
        return client
    }
#endif
}
