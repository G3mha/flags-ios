import SwiftUI
import WidgetKit

struct FlagEntry: TimelineEntry {
    let date = Date()
}

/// The flag never changes, so one entry with `.never` costs us no refresh budget.
struct FlagProvider: TimelineProvider {
    func placeholder(in context: Context) -> FlagEntry { FlagEntry() }

    func getSnapshot(in context: Context, completion: @escaping (FlagEntry) -> Void) {
        completion(FlagEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FlagEntry>) -> Void) {
        completion(Timeline(entries: [FlagEntry()], policy: .never))
    }
}

private let families: [WidgetFamily] = [
    .accessoryCircular, .accessoryCorner, .accessoryRectangular, .accessoryInline,
]

struct AssetWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "spike.asset", provider: FlagProvider()) { _ in
            FlagSpikeView(variant: .asset).containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("1 Asset")
        .supportedFamilies(families)
    }
}

struct AssetAccentedWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "spike.assetAccented", provider: FlagProvider()) { _ in
            FlagSpikeView(variant: .assetAccented).containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("2 Asset FC")
        .supportedFamilies(families)
    }
}

struct EmojiWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "spike.emoji", provider: FlagProvider()) { _ in
            FlagSpikeView(variant: .emoji).containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("3 Emoji")
        .supportedFamilies(families)
    }
}

struct ShapesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "spike.shapes", provider: FlagProvider()) { _ in
            FlagSpikeView(variant: .shapes).containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("4 Shapes")
        .supportedFamilies(families)
    }
}

@main
struct FlagSpikeBundle: WidgetBundle {
    var body: some Widget {
        AssetWidget()
        AssetAccentedWidget()
        EmojiWidget()
        ShapesWidget()
    }
}
