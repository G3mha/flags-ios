import AppIntents
import FlagKit
import SwiftUI
import WidgetKit

struct FlagWidget: Widget {
    /// Stored in people's widget configuration. Changing it orphans every
    /// widget already placed.
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
        .description("Keep a flag on your Home Screen or Lock Screen.")
        .supportedFamilies([
            .systemSmall,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
        ])
    }
}

@main
struct FlagsWidgetBundle: WidgetBundle {
    var body: some Widget {
        FlagWidget()
    }
}

/// Pulls FlagKit's intent metadata into this extension. See FlagKitAppIntents.
struct FlagsWidgetsAppIntents: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] {
        [FlagKitAppIntents.self]
    }
}
