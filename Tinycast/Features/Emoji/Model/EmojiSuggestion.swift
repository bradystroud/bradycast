import Foundation

/// The pure half of AI emoji search: what to ask, and which answers the grid can show.
enum EmojiSuggestion {
    static let minimumQueryLength = 2
    static let maximumCount = 10
    /// Long enough that a typist mid-word never starts a generation the next key cancels.
    static let debounce: Duration = .milliseconds(350)
    static let instructions = """
        You suggest emoji for an emoji picker. Given a topic, which may be a person, place, brand, \
        mood or phrase, reply with the single emoji people most associate with it, most fitting \
        first. Use only standard Unicode emoji, no text and no repeats.
        """

    /// The cache and staleness key: case and spacing never change what the model is asked.
    static func key(_ query: String) -> String {
        query.lowercased()
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    /// Catalog glyphs in answer order, deduplicated; `resolve` maps a spelling to its glyph.
    static func glyphs(in answer: [String], resolve: (String) -> String?) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for character in answer.joined() {
            guard let glyph = catalogGlyph(for: String(character), resolve: resolve),
                seen.insert(glyph).inserted
            else { continue }
            result.append(glyph)
            if result.count == maximumCount { break }
        }
        return result
    }

    /// The model writes 🛠 or 🛠️ and toned people freely; the catalog keys one untoned form.
    private static func catalogGlyph(
        for candidate: String, resolve: (String) -> String?
    ) -> String? {
        if let glyph = resolve(candidate) { return glyph }
        let bare = String(
            String.UnicodeScalarView(
                candidate.unicodeScalars.filter { !isPresentationOrTone($0) }))
        guard !bare.isEmpty else { return nil }
        if let glyph = resolve(bare) { return glyph }
        var scalars = Array(bare.unicodeScalars)
        scalars.insert(variationSelector, at: 1)
        return resolve(String(String.UnicodeScalarView(scalars)))
    }

    private static let variationSelector = Unicode.Scalar(0xFE0F)!

    private static func isPresentationOrTone(_ scalar: Unicode.Scalar) -> Bool {
        scalar == variationSelector || (0x1F3FB...0x1F3FF).contains(scalar.value)
    }
}
