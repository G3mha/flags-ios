import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Flags someone has opened lately, newest first.
///
/// This exists because of a hard limit on the watch: the complication picker
/// offers exactly what `recommendations()` returns and nothing else. There is
/// no "browse all" behind it, so without something like this a flag has to be
/// starred before it can go on a watch face, and wanting a flag on your wrist
/// for an afternoon is not the same as wanting it in a permanent list.
///
/// Opening a flag's page is a weaker signal than starring it, and a fair one:
/// it is what someone is already doing just before they go looking for the
/// watch face. So it is enough to make the flag offerable, and it costs no
/// decision.
///
/// Deliberately per-device and not synced. Favourites say what someone cares
/// about and belong on every device they own; recents say what they were
/// looking at on *this* one, which does not travel meaningfully.
///
/// Stored as a plain ordered list. The order is the whole of the information,
/// so there is nothing to timestamp and nothing to merge.
public enum Recents {
    static let key = "recents"

    /// How many to keep. Comfortably more than the gallery will show, so the
    /// shortlist is what does the trimming rather than this.
    static let limit = 40

    /// Note that someone looked at this flag.
    ///
    /// Moves an already-present flag back to the front rather than adding it
    /// twice, so the list reads as "last seen" rather than "seen most often".
    public static func record(
        _ id: FlagID,
        in defaults: UserDefaults = Favourites.sharedDefaults
    ) {
        var ids = self.ids(in: defaults)
        ids.removeAll { $0 == id }
        ids.insert(id, at: 0)
        defaults.set(try? JSONEncoder().encode(Array(ids.prefix(limit))), forKey: key)

        // Same reason Favourites does it: the gallery's shortlist is cached
        // and nothing re-runs it just because this list moved.
        #if canImport(WidgetKit)
        WidgetCenter.shared.invalidateConfigurationRecommendations()
        #endif
    }

    public static func ids(in defaults: UserDefaults = Favourites.sharedDefaults) -> [FlagID] {
        guard let data = defaults.data(forKey: key),
              let ids = try? JSONDecoder().decode([FlagID].self, from: data)
        else { return [] }
        return ids
    }

    /// For tests, and for a settings screen if one ever wants to offer it.
    public static func clear(in defaults: UserDefaults = Favourites.sharedDefaults) {
        defaults.removeObject(forKey: key)
    }
}
