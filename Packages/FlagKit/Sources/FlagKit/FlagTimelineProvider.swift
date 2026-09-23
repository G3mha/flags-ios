import Foundation
import SwiftUI
import WidgetKit

public struct FlagEntry: TimelineEntry, Sendable {
    public let date: Date
    public let flag: Flag?

    public init(date: Date = .now, flag: Flag?) {
        self.date = date
        self.flag = flag
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
        FlagEntry(flag: configuration.flag?.flag ?? .default)
    }

    public func timeline(for configuration: SelectFlagIntent, in context: Context) async -> Timeline<FlagEntry> {
        Timeline(entries: [FlagEntry(flag: configuration.flag?.flag ?? .default)], policy: .never)
    }

    /// What the widget gallery offers before anyone configures anything.
    ///
    /// Leading with the device's own region means the common case — someone
    /// wanting the flag of where they are, or where they are from — is one tap.
    /// Listing all 250 here would bury the gallery.
    public func recommendations() -> [AppIntentRecommendation<SelectFlagIntent>] {
        var suggested: [Flag] = []
        if let region = Locale.current.region?.identifier,
           let local = FlagRegistry.shared.flag(for: FlagID(collection: Countries.id, code: region)) {
            suggested.append(local)
        }
        if let fallback = Flag.default, !suggested.contains(fallback) {
            suggested.append(fallback)
        }
        return suggested.map { flag in
            AppIntentRecommendation(
                intent: SelectFlagIntent(flag: FlagEntity(flag: flag)),
                description: Text(flag.name)
            )
        }
    }
}
