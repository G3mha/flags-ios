import Foundation

/// A named group of flags — countries today; clubs, games or anything else later.
///
/// A new pack conforms to this and gets added to `FlagRegistry.shared`. Nothing
/// in the widgets, the picker or the App Intents configuration needs to change.
public protocol FlagCollection: Sendable {
    static var id: String { get }
    static var displayName: String { get }
    static var flags: [Flag] { get }
}

/// Every collection the app knows about.
///
/// Deliberately immutable. Packs are compiled in, so there is no need for a
/// mutable global and no chance of a widget extension seeing a different set
/// than the app. If packs ever become downloadable this is the seam to change.
public struct FlagRegistry: Sendable {
    public static let shared = FlagRegistry(collections: [])

    public let collections: [any FlagCollection.Type]

    public init(collections: [any FlagCollection.Type]) {
        self.collections = collections
    }

    public var allFlags: [Flag] {
        collections.flatMap { $0.flags }
    }

    public func collection(id: String) -> (any FlagCollection.Type)? {
        collections.first { $0.id == id }
    }

    public func flag(for id: FlagID) -> Flag? {
        collection(id: id.collection)?.flags.first { $0.id == id }
    }

    /// Prefix matches first, so typing "bra" puts Brazil above Gibraltar.
    public func search(_ query: String, limit: Int = 50) -> [Flag] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return Array(allFlags.prefix(limit)) }

        var prefixed: [Flag] = []
        var contained: [Flag] = []
        for flag in allFlags where flag.matches(q) {
            if flag.searchTerms.contains(where: { $0.hasPrefix(q) }) {
                prefixed.append(flag)
            } else {
                contained.append(flag)
            }
        }
        return Array((prefixed + contained).prefix(limit))
    }
}
