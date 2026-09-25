import Foundation
import SwiftUI
import WidgetKit

public struct FlagEntry: TimelineEntry, Sendable {
    public let date: Date
    public let flag: Flag?
    public let presentation: FlagPresentation

    public init(date: Date = .now, flag: Flag?, presentation: FlagPresentation = .circle) {
        self.date = date
        self.flag = flag
        self.presentation = presentation
    }
}

/// A flag does not change, so the timeline is one entry that never expires.
/// That costs no refresh budget, which is why a complication showing one can
/// sit on a watch face indefinitely without the system throttling it.
public struct FlagTimelineProvider: AppIntentTimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> FlagEntry {
        FlagEntry(flag: .default)
    }

    public func snapshot(for configuration: SelectFlagIntent, in context: Context) async -> FlagEntry {
        FlagEntry(flag: configuration.flag?.flag ?? .default,
                  presentation: configuration.presentation)
    }

    public func timeline(for configuration: SelectFlagIntent, in context: Context) async -> Timeline<FlagEntry> {
        let entry = FlagEntry(flag: configuration.flag?.flag ?? .default,
                              presentation: configuration.presentation)
        return Timeline(entries: [entry], policy: .never)
    }

    /// How many the gallery is willing to show.
    ///
    /// Larger than a shortlist would suggest, because on the watch this is not
    /// a shortlist — the complication picker offers these and nothing else, so
    /// anything cut here is a flag that cannot go on a watch face at all. The
    /// gallery scrolls, so the cost of a longer list is mild next to that.
    static let maxRecommendations = 25

    /// What the widget gallery offers before anyone configures anything.
    ///
    /// Favourites lead. Someone who starred a flag has already said which ones
    /// they care about, and that beats anything we can infer — and because
    /// favourites travel over iCloud, starring a flag on the phone puts it in
    /// the watch's complication gallery.
    ///
    /// The device's region follows, so someone who has starred nothing still
    /// gets the flag of where they are in one tap, and the default last.
    ///
    /// None of this limits what can be chosen. The gallery is a shortlist; the
    /// complication's own settings list every flag with a search field.
    public func recommendations() -> [AppIntentRecommendation<SelectFlagIntent>] {
        Self.suggestedFlags(
            favourites: Favourites.storedIDs(),
            deviceRegion: Locale.current.region?.identifier
        )
        .map { flag in
            AppIntentRecommendation(
                intent: SelectFlagIntent(flag: FlagEntity(flag: flag)),
                description: Text(flag.name)
            )
        }
    }

    /// Favourites first, then the device's region, then the default, with
    /// duplicates dropped and the whole thing capped.
    ///
    /// Split out from `recommendations()` because that returns WidgetKit types
    /// that are awkward to assert on, while the choosing is the part with the
    /// behaviour worth testing.
    static func suggestedFlags(
        favourites: [FlagID],
        deviceRegion: String?,
        registry: FlagRegistry = .shared,
        limit: Int = maxRecommendations
    ) -> [Flag] {
        var suggested: [Flag] = []

        func add(_ flag: Flag?) {
            guard let flag, !suggested.contains(flag) else { return }
            suggested.append(flag)
        }

        for id in favourites { add(registry.flag(for: id)) }
        if let deviceRegion {
            add(registry.flag(for: FlagID(collection: Countries.id, code: deviceRegion)))
        }
        add(Flag.default)

        return Array(suggested.prefix(limit))
    }
}
