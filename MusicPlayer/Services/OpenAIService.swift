import Foundation

final class OpenAIService {
    static let shared = OpenAIService()

    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let model = "gpt-4o-mini"

    private init() {}

    func generateFact(for track: Track) async throws -> String {
        let language = Locale.current.language.languageCode?.identifier ?? "en"

    let systemPrompt = """
        You write ONE short factual note for a music player.

        This is NOT a description, not a review, not a summary.
        It MUST be a specific, real, verifiable fact.

        Goal:
        Give a listener a small but meaningful insight that adds depth to what is currently playing.

        Priority:
        1. The track itself
        2. The album / release
        3. The artist
        4. A closely related musical or cultural context

        Selection rules:
        - First look for a fact that reveals something hidden, surprising, or non-obvious.
        - Prefer concrete details about: origin, influence, sample, collaboration, production, artwork, meaning, or context.
        - Avoid the most obvious fact.
        - If it sounds like a Wikipedia opening line, reject it and choose another.

        Strictly avoid:
        - release dates unless truly exceptional
        - chart positions
        - genre descriptions
        - generic artist or album summaries
        - phrases like:
        "was released", "reached number", "is a song by", "features a blend",
        "showcases", "reflects", "signature style", "critically acclaimed"

        Hard requirements:
        - Must include at least one concrete element (name, event, source, collaboration, or specific detail)
        - If the fact could apply to many songs, it is invalid

        Truth rules:
        - Only use well-known, widely documented facts
        - Never guess, invent, or speculate
        - If no strong fact exists, use a simple but still specific one (not generic)

        Style:
        - One sentence only
        - Max 120 characters
        - Dense and precise
        - No filler
        - No intro phrases
        - No quotes
        - No emoji

        Before output:
        - Reject obvious or generic facts
        - Reject anything that feels like a safe default

        Write in \(language).

        Return only the final sentence.
        """

        let albumLine = {
            if let album = track.albumTitle, !album.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "Album: \(album)"
            } else {
                return "Album: Unknown"
            }
        }()

        let userPrompt = """
        Current track:
        Title: \(track.title)
        Artist: \(track.artist)
        \(albumLine)

        Write one short verified context note with the priority and quality rules above.
        """

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "max_tokens": 80,
            "temperature": 0.35
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(APIKeys.openAI)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw OpenAIError.requestFailed
        }

        let parsed = try JSONDecoder().decode(ChatCompletion.self, from: data)

        guard let text = parsed.choices.first?.message.content?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            throw OpenAIError.emptyResponse
        }

        return text
    }
}

enum OpenAIError: Error {
    case requestFailed
    case emptyResponse
}

// MARK: - Response Models

private struct ChatCompletion: Decodable {
    let choices: [Choice]
}

private struct Choice: Decodable {
    let message: Message
}

private struct Message: Decodable {
    let content: String?
}