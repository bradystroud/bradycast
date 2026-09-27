import Foundation
import FoundationModels

/// On-device emoji ideas for what keywords cannot reach — "elon musk" answers ⚡🚀 rather than 🎹.
@MainActor
@Observable
final class EmojiSuggester {
    /// The key the published glyphs answer, so a stale answer never shows under a newer query.
    private(set) var answeredKey = ""
    private(set) var glyphs: [String] = []
    /// The key a generation is running for, from the pause before it until its answer lands.
    private(set) var pendingKey: String?

    @ObservationIgnored private var cache: [String: [String]] = [:]
    @ObservationIgnored private var cacheOrder: [String] = []
    private static let cacheLimit = 200

    func glyphs(for query: String) -> [String] {
        EmojiSuggestion.key(query) == answeredKey ? glyphs : []
    }

    func isLoading(for query: String) -> Bool {
        pendingKey != nil && EmojiSuggestion.key(query) == pendingKey
    }

    /// Run from a view's `.task(id:)`, whose cancellation on the next keystroke is the debounce.
    func suggest(for query: String, index: EmojiIndex) async {
        let key = EmojiSuggestion.key(query)
        guard key.count >= EmojiSuggestion.minimumQueryLength, key != answeredKey else { return }
        if let cached = cache[key] {
            publish(cached, for: key)
            return
        }
        guard index.isLoaded, SystemLanguageModel.default.isAvailable else { return }
        pendingKey = key
        // The next keystroke's task has already claimed the key by the time this one unwinds.
        defer { if pendingKey == key { pendingKey = nil } }
        do {
            try await Task.sleep(for: EmojiSuggestion.debounce)
            let generation = Task.detached(priority: .userInitiated) {
                try await Self.generate(key)
            }
            let answer = try await withTaskCancellationHandler {
                try await generation.value
            } onCancel: {
                generation.cancel()
            }
            let found = EmojiSuggestion.glyphs(in: answer) { index.entry(for: $0)?.glyph }
            remember(found, for: key)
            publish(found, for: key)
        } catch {
            // A refusal or a busy model shows nothing and is not cached, so a retype asks again.
            return
        }
    }

    private func publish(_ found: [String], for key: String) {
        answeredKey = key
        glyphs = found
    }

    private func remember(_ found: [String], for key: String) {
        if cache.updateValue(found, forKey: key) == nil { cacheOrder.append(key) }
        if cacheOrder.count > Self.cacheLimit { cache[cacheOrder.removeFirst()] = nil }
    }

    /// Permissive guardrails: `.default` refuses many a public figure's name outright.
    private nonisolated static func generate(_ topic: String) async throws -> [String] {
        let session = LanguageModelSession(
            model: SystemLanguageModel(guardrails: .permissiveContentTransformations),
            instructions: EmojiSuggestion.instructions)
        let response = try await session.respond(
            to: "Topic: \(topic)", generating: EmojiIdeas.self,
            options: GenerationOptions(temperature: 0))
        return response.content.emoji
    }
}

@Generable
private struct EmojiIdeas {
    @Guide(
        description: "Single emoji characters most associated with the topic, best first",
        .count(EmojiSuggestion.maximumCount))
    var emoji: [String]
}
