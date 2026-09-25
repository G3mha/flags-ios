import AppIntents
import FlagKit
import SwiftUI
import WidgetKit

struct FlagComplication: Widget {
    /// Matches the iOS widget's kind so a flag placed on one platform reads as
    /// the same widget on the other.
    static let kind = "dev.enriccogemha.flags.flag"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: Self.kind,
            intent: SelectFlagIntent.self,
            provider: FlagTimelineProvider()
        ) { entry in
            FlagWidgetView(entry: entry)
        }
        .configurationDisplayName("Flag")
        .description("Keep a flag on your watch face.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryRectangular,
            .accessoryInline,
        ])
    }
}

@main
struct FlagsWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        FlagComplication()
    }
}

/// Pulls FlagKit's intent metadata into this extension. See FlagKitAppIntents.
struct FlagsWatchWidgetsAppIntents: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] {
        [FlagKitAppIntents.self]
    }
}
