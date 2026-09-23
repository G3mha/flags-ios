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
}
