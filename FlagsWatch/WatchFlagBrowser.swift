import FlagKit
import SwiftUI

/// Browsing 257 flags on a watch only works with search and favourites; a flat
/// scroll of that length is not something anyone finishes.
struct WatchFlagBrowser: View {
    @Environment(Favourites.self) private var favourites
    @State private var query = ""

    private var results: [Flag] {
        FlagRegistry.shared.search(query, limit: .max)
    }

    private var favouriteFlags: [Flag] {
        query.isEmpty ? favourites.flags() : []
    }

    var body: some View {
        NavigationStack {
            List {
                if !favouriteFlags.isEmpty {
                    Section("Favourites") {
                        ForEach(favouriteFlags) { row(for: $0) }
                    }
                }

                Section(favouriteFlags.isEmpty ? "" : "All flags") {
                    ForEach(results) { row(for: $0) }
                }

                if query.isEmpty {
                    Section {
                        NavigationLink {
                            WatchComplicationTip()
                        } label: {
                            Label("Add to your watch face", systemImage: "questionmark.circle")
                                .font(.footnote)
                        }
                    }
                }
            }
            .navigationTitle("Flags")
            .searchable(text: $query, prompt: "Search")
            .overlay {
                if results.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
            }
        }
    }

    private func row(for flag: Flag) -> some View {
        NavigationLink {
            WatchFlagDetail(flag: flag)
        } label: {
            HStack(spacing: 10) {
                FlagSquare(flag: flag, cornerRadius: 7)
                    .frame(width: 30, height: 30)
                Text(flag.name)
                    .font(.body)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.vertical, 2)
        }
    }
}

private struct WatchFlagDetail: View {
    let flag: Flag
    @Environment(Favourites.self) private var favourites

    private var isFavourite: Bool { favourites.contains(flag.id) }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                FlagSquare(flag: flag, cornerRadius: 18)
                    .frame(maxWidth: 120)

                Text(flag.name)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Button {
                    withAnimation(.snappy) { favourites.toggle(flag.id) }
                } label: {
                    Label(
                        isFavourite ? "Favourite" : "Add to favourites",
                        systemImage: isFavourite ? "star.fill" : "star"
                    )
                    .font(.footnote)
                }
                .buttonStyle(.bordered)
                .tint(isFavourite ? .yellow : .accentColor)
                .sensoryFeedback(.selection, trigger: isFavourite)
            }
            .padding(.vertical, 8)
        }
        .navigationTitle(flag.abbreviation)
        // The complication picker offers recommendations and nothing else, so
        // this is what lets someone put a flag on a face without starring it.
        .task { Recents.record(flag.id) }
    }
}

private struct WatchComplicationTip: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(index + 1)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.black)
                            .frame(width: 16, height: 16)
                            .background(.tint, in: .circle)
                        Text(step)
                            .font(.footnote)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.vertical, 6)
        }
        .navigationTitle("Watch face")
    }

    private let steps = [
        "Press and hold this watch face, then tap Edit.",
        "Swipe to Complications and tap a slot.",
        "Choose Flags, then pick your flag.",
    ]
}

#Preview {
    WatchFlagBrowser()
        .environment(Favourites())
}
