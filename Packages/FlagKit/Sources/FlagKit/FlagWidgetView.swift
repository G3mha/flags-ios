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
        if let flag = entry.flag {
            content(for: flag)
        } else {
            // The configured flag's collection is gone — a pack removed in an
            // update, say. Better than an empty slot with no explanation.
            Image(systemName: "flag.slash")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private func content(for flag: Flag) -> some View {
        switch family {
        case .accessoryInline:
            Text(flag.name)

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
