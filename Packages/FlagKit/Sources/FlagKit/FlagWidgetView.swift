import SwiftUI
import WidgetKit

/// One view for every widget family on both platforms.
///
/// Only the families that exist on iOS *and* watchOS are matched by name;
/// everything else falls through to the circular treatment, which keeps this
/// free of platform conditionals.
public struct FlagWidgetView: View {
    @Environment(\.widgetFamily) private var family
    private let entry: FlagEntry

    public init(entry: FlagEntry) {
        self.entry = entry
    }

    public var body: some View {
        content
            .containerBackground(for: .widget) { background }
    }

    /// Whether this family's content already reaches its own edges.
    ///
    /// Accessory widgets do: a circular complication's content fills the circle
    /// with no inset. Home Screen widgets do not — WidgetKit pads their content,
    /// so a foreground flag stops short however hard it is told to expand, and
    /// only the container background bleeds. Fill therefore has to come from a
    /// different place depending on the family.
    private var contentReachesEdges: Bool {
        #if os(watchOS)
        true
        #else
        switch family {
        case .accessoryCircular, .accessoryRectangular, .accessoryInline: true
        default: false
        }
        #endif
    }

    @ViewBuilder private var content: some View {
        if let flag = entry.flag {
            foreground(for: flag)
        } else {
            // The configured flag's collection is gone — a pack removed in an
            // update, say. Better than an empty slot with no explanation.
            Image(systemName: "flag.slash")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private var background: some View {
        if entry.presentation == .fill, !contentReachesEdges, let flag = entry.flag {
            FlagView(flag: flag, shape: .natural)
        } else {
            #if os(watchOS)
            Color.clear
            #else
            Color.clear.background(.fill.tertiary)
            #endif
        }
    }

    @ViewBuilder private func foreground(for flag: Flag) -> some View {
        switch family {
        case .accessoryInline:
            // Text only by definition; there is nowhere to put artwork.
            Text(flag.name)

        case _ where entry.presentation == .fill:
            if contentReachesEdges {
                FlagView(flag: flag, shape: .natural)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Already filling the container behind this.
                Color.clear
            }

        case .accessoryRectangular:
            HStack(spacing: 8) {
                FlagView(flag: flag, shape: .roundedRect(cornerRadius: 6))
                    .frame(width: 38, height: 38)
                Text(flag.name)
                    .font(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
            }

        default:
            FlagView(flag: flag, shape: .circle)
        }
    }
}
