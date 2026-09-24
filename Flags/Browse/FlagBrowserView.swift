import FlagKit
import SwiftUI

/// The app's one screen: find a flag, then learn how to put it somewhere.
///
/// A grid rather than a list because flags are the content — at list-row size
/// a dozen of them are indistinguishable smudges of red and white.
struct FlagBrowserView: View {
    @Environment(Favourites.self) private var favourites
    @State private var query = ""
    @State private var showingGuide = false

    private let columns = [GridItem(.adaptive(minimum: 96, maximum: 140), spacing: 16)]

    private var results: [Flag] {
        FlagRegistry.shared.search(query, limit: .max)
    }

    private var favouriteFlags: [Flag] {
        query.isEmpty ? favourites.flags() : []
    }

    /// Continent headings while browsing; one flat run of hits while searching,
    /// because when you have typed "bra" you want the answer, not a taxonomy.
    private var sections: [(title: String, flags: [Flag])] {
        guard query.isEmpty else { return [("Results", results)] }
        return Dictionary(grouping: results) { $0.group ?? "Elsewhere" }
            .sorted { $0.key < $1.key }
            .map { ($0.key, $0.value) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20, pinnedViews: .sectionHeaders) {
                    if !favouriteFlags.isEmpty {
                        Section {
                            ForEach(favouriteFlags) { flag in
                                tile(for: flag)
                            }
                        } header: {
                            SectionHeader(title: "Favourites", systemImage: "star.fill")
                        }
                    }

                    ForEach(sections, id: \.title) { section in
                        Section {
                            ForEach(section.flags) { flag in
                                tile(for: flag)
                            }
                        } header: {
                            if query.isEmpty {
                                SectionHeader(title: section.title, systemImage: "globe")
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                .safeAreaPadding(.bottom, 56)
            }
            .navigationTitle("Flags")
            .searchable(text: $query, prompt: "Country or code")
            .autocorrectionDisabled()
            .overlay {
                if results.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("How to add a flag", systemImage: "questionmark.circle") {
                        showingGuide = true
                    }
                }
            }
            .sheet(isPresented: $showingGuide) {
                NavigationStack { AddWidgetGuide() }
            }
            .navigationDestination(for: Flag.self) { flag in
                FlagDetailView(flag: flag)
            }
        }
    }

    private func tile(for flag: Flag) -> some View {
        NavigationLink(value: flag) {
            FlagTile(flag: flag, isFavourite: favourites.contains(flag.id))
        }
        .buttonStyle(.plain)
    }
}

private struct SectionHeader: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption2)
            Text(title)
                .font(.subheadline.weight(.semibold))
            Spacer()
        }
        .foregroundStyle(.secondary)
        .padding(.vertical, 8)
        .background(.background)
    }
}

#Preview {
    FlagBrowserView()
        .environment(Favourites())
}
