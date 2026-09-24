import Foundation
import Observation

/// The flags someone has starred, newest first.
///
/// Stored in `UserDefaults` as raw `FlagID` strings so the list survives a flag
/// disappearing from a collection — an unknown id is dropped on read rather
/// than crashing or resurrecting later.
@Observable
public final class Favourites {
    private static let key = "favourites"

    private let defaults: UserDefaults
    public private(set) var ids: [FlagID]

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.ids = (defaults.array(forKey: Self.key) as? [String] ?? [])
            .compactMap(FlagID.init(rawValue:))
    }

    public func contains(_ id: FlagID) -> Bool {
        ids.contains(id)
    }

    public func toggle(_ id: FlagID) {
        if let index = ids.firstIndex(of: id) {
            ids.remove(at: index)
        } else {
            ids.insert(id, at: 0)
        }
        persist()
    }

    public func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        ids.move(fromOffsets: source, toOffset: destination)
        persist()
    }

    /// Resolved against the registry, skipping anything no longer available.
    public func flags(in registry: FlagRegistry = .shared) -> [Flag] {
        ids.compactMap(registry.flag(for:))
    }

    private func persist() {
        defaults.set(ids.map(\.rawValue), forKey: Self.key)
    }
}
