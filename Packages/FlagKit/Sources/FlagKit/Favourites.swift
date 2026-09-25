import Foundation
import Observation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// One flag's starred state and when it last changed.
///
/// The timestamp is what makes syncing behave. Storing a plain list of starred
/// ids would leave no way to tell "this device has not heard about Japan yet"
/// apart from "this device deliberately unstarred Japan", so either additions
/// or removals would get lost depending on which way the merge leaned.
struct FavouriteRecord: Codable, Equatable, Sendable {
    let id: FlagID
    var starred: Bool
    var changed: Date
}

/// Holds the notification observer so it is removed when `Favourites` goes
/// away. It lives in its own object because `deinit` is nonisolated and cannot
/// touch a main-actor property.
private final class ObserverToken: @unchecked Sendable {
    var value: NSObjectProtocol?

    deinit {
        if let value { NotificationCenter.default.removeObserver(value) }
    }
}

/// The flags someone has starred, newest first, shared across their devices.
///
/// Written to `UserDefaults` always and to iCloud's key-value store as well.
/// The local copy is the one read at launch, so the list is there instantly and
/// still works with no iCloud account, no network, or no entitlement. iCloud is
/// the channel between devices, not the source of truth.
/// Main-actor isolated: this is UI state, read from views, and the iCloud
/// change notification is delivered on the main queue anyway.
@MainActor
@Observable
public final class Favourites {
    // nonisolated so storedIDs can read the store off the main actor.
    private nonisolated static let key = "favourites"

    /// The container the app and its widget extensions share.
    ///
    /// An extension gets its own data container, so `UserDefaults.standard`
    /// inside one is a different store from the app's — a favourite starred in
    /// the app is simply not there when the complication gallery looks. The
    /// app group is the only way across that boundary.
    ///
    /// Within one device. Between devices is iCloud's job; see `cloudStore`.
    /// Computed rather than stored because `UserDefaults` is not `Sendable`,
    /// so it cannot be a nonisolated static constant. Each call hands back a
    /// separate object over the same backing store, which is what matters.
    public nonisolated static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: "group.dev.enriccogemha.flags") ?? .standard
    }

    private let local: UserDefaults
    private let cloud: NSUbiquitousKeyValueStore?
    private var records: [FlagID: FavouriteRecord]
    private let observer = ObserverToken()

    /// Starred flags, most recently starred first.
    public var ids: [FlagID] {
        records.values
            .filter(\.starred)
            .sorted { $0.changed > $1.changed }
            .map(\.id)
    }

    /// - Parameter cloud: `.default` once the app carries the iCloud
    ///   Key-value storage capability, nil otherwise.
    ///
    ///   It defaults to nil deliberately. Touching
    ///   `NSUbiquitousKeyValueStore.default` without the
    ///   `com.apple.developer.ubiquity-kvstore-identifier` entitlement logs a
    ///   fault on every launch — "BUG IN CLIENT OF KVS" — and syncs nothing,
    ///   so the capability has to come first. See `Favourites.cloudStore`.
    public init(
        local: UserDefaults = Favourites.sharedDefaults,
        cloud: NSUbiquitousKeyValueStore? = nil
    ) {
        self.local = local
        self.cloud = cloud
        var merged = Self.merge(
            Self.decode(local.data(forKey: Self.key)),
            Self.decode(cloud?.data(forKey: Self.key))
        )
        // Carry over anything starred before favourites moved into the app
        // group. Merging rather than copying means a record already in the
        // group wins if it is the newer of the two.
        if local != .standard {
            merged = Self.merge(merged, Self.decode(UserDefaults.standard.data(forKey: Self.key)))
        }
        self.records = merged
        startObservingCloud()
        cloud?.synchronize()
    }


    /// The store the apps pass in.
    ///
    /// Both apps carry the iCloud Key-value storage entitlement, naming the
    /// same store, so favourites follow the person between their phone and
    /// their watch.
    ///
    /// Set this back to nil if the capability is ever removed: reaching for
    /// `.default` without the entitlement logs a fault on every launch and
    /// syncs nothing.
    public static var cloudStore: NSUbiquitousKeyValueStore? {
        .default
    }

    public func contains(_ id: FlagID) -> Bool {
        records[id]?.starred ?? false
    }

    public func toggle(_ id: FlagID) {
        records[id] = FavouriteRecord(id: id, starred: !contains(id), changed: Date())
        persist()
    }

    /// Resolved against the registry, skipping anything no longer available.
    public func flags(in registry: FlagRegistry = .shared) -> [Flag] {
        ids.compactMap(registry.flag(for:))
    }

    /// Starred flags, newest first, read without the main actor.
    ///
    /// `recommendations()` is nonisolated and synchronous, so it cannot build a
    /// `Favourites`. It only wants the ids, and those are JSON sitting in the
    /// shared container, so reading them directly costs nothing and keeps the
    /// widget extension off the main actor.
    public nonisolated static func storedIDs(
        in defaults: UserDefaults = Favourites.sharedDefaults
    ) -> [FlagID] {
        decode(defaults.data(forKey: key))
            .values
            .filter(\.starred)
            .sorted { $0.changed > $1.changed }
            .map(\.id)
    }

    // MARK: - Syncing

    /// Takes the later record for each flag.
    ///
    /// Two devices starring different flags keep both. A device that unstarred
    /// something more recently than another starred it wins, and vice versa,
    /// which is the behaviour people expect from the last thing they touched.
    nonisolated static func merge(
        _ a: [FlagID: FavouriteRecord],
        _ b: [FlagID: FavouriteRecord]
    ) -> [FlagID: FavouriteRecord] {
        a.merging(b) { mine, theirs in theirs.changed > mine.changed ? theirs : mine }
    }

    private nonisolated static func decode(_ data: Data?) -> [FlagID: FavouriteRecord] {
        guard let data,
              let records = try? JSONDecoder().decode([FavouriteRecord].self, from: data)
        else { return [:] }
        return Dictionary(records.map { ($0.id, $0) }, uniquingKeysWith: { $1 })
    }

    private func startObservingCloud() {
        guard let cloud else { return }
        observer.value = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloud,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.pullFromCloud() }
        }
    }

    /// Another device changed something. Merge rather than overwrite, so a
    /// change made here while offline is not thrown away by the first sync.
    private func pullFromCloud() {
        guard let cloud else { return }
        let merged = Self.merge(records, Self.decode(cloud.data(forKey: Self.key)))
        guard merged != records else { return }
        records = merged
        writeLocal()
        // The change came from another device, so the shortlist here is stale
        // for the same reason it is after a local toggle.
        notifyWidgets()
    }

    private func persist() {
        writeLocal()
        if let data = encoded() {
            cloud?.set(data, forKey: Self.key)
        }
        notifyWidgets()
    }

    /// Tell the system the gallery's shortlist has changed.
    ///
    /// `recommendations()` is cached, and nothing re-runs it just because the
    /// stored favourites moved — a flag starred in the app simply never shows
    /// up in the complication gallery until something else invalidates it.
    /// This is the call that makes starring a flag actually reach the gallery.
    private func notifyWidgets() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.invalidateConfigurationRecommendations()
        #endif
    }

    private func writeLocal() {
        local.set(encoded(), forKey: Self.key)
    }

    private func encoded() -> Data? {
        try? JSONEncoder().encode(Array(records.values))
    }
}
