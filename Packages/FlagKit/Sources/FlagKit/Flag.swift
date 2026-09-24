import Foundation

/// Identifies one flag within one collection, e.g. `countries/br`.
///
/// The collection half is what keeps this open to non-country flags later —
/// `clubs/sepalmeiras` and `countries/br` coexist without either knowing about
/// the other.
public struct FlagID: Hashable, Codable, Sendable, CustomStringConvertible {
    public let collection: String
    public let code: String

    public init(collection: String, code: String) {
        self.collection = collection
        self.code = code.lowercased()
    }

    /// Round-trips through `init?(rawValue:)`. Stored in widget configuration,
    /// so changing this format breaks people's existing complications.
    public var rawValue: String { "\(collection)/\(code)" }

    public init?(rawValue: String) {
        let parts = rawValue.split(separator: "/", maxSplits: 1)
        guard parts.count == 2 else { return nil }
        self.init(collection: String(parts[0]), code: String(parts[1]))
    }

    public var description: String { rawValue }
}

/// How a flag's artwork is obtained.
///
/// Emoji needs nothing bundled and covers every country the system knows, so
/// the app works before any asset pipeline exists. Asset artwork is higher
/// fidelity and is what a shipped build should prefer where it has one.
public enum FlagArtwork: Hashable, Sendable {
    case emoji(String)
    case asset(name: String)
}

public struct Flag: Identifiable, Hashable, Sendable {
    public let id: FlagID
    /// Already localized for display; see `Countries` for where this comes from.
    public let name: String
    /// Lowercased terms used for matching. Includes the code and the name.
    public let searchTerms: [String]
    public let artwork: FlagArtwork
    /// Drawn when the system flattens the widget to a single tint, where the
    /// artwork's colours would be lost anyway.
    public let abbreviation: String
    /// False for a flag that still resolves and draws, but is not offered in
    /// a picker. See `Countries.restrictions` for the only current use.
    public let isListed: Bool
    /// A heading to file this flag under when browsing — the continent for a
    /// country, a league for a club. Nil when a collection has no useful
    /// grouping, in which case the browser shows one flat run.
    public let group: String?

    public init(
        id: FlagID,
        name: String,
        searchTerms: [String] = [],
        artwork: FlagArtwork,
        abbreviation: String,
        isListed: Bool = true,
        group: String? = nil
    ) {
        self.id = id
        self.name = name
        self.artwork = artwork
        self.abbreviation = abbreviation
        self.isListed = isListed
        self.group = group
        self.searchTerms = (searchTerms + [name, id.code]).map { $0.lowercased() }
    }

    public func matches(_ query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return true }
        return searchTerms.contains { $0.hasPrefix(q) || $0.contains(q) }
    }
}
