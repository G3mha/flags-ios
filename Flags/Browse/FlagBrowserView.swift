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
    /// The flag at the top of the viewport.
    @State private var topFlag: FlagID?
    /// Whether the list has scrolled far enough for the large title to have
    /// collapsed into the bar.
    @State private var titleCollapsed = false

    private var results: [Flag] {
        FlagRegistry.shared.search(query, limit: .max)
    }

    private var favouriteFlags: [Flag] {
        query.isEmpty ? favourites.flags() : []
    }

    /// Continent headings while browsing; one flat run of hits while searching,
    /// because when you have typed "bra" you want the answer, not a taxonomy.
    private var sections: [FlagSection] {
        guard query.isEmpty else { return [FlagSection(title: "Results", flags: results, hasHeader: false)] }
        return Dictionary(grouping: results) { $0.group ?? "Elsewhere" }
            .sorted { $0.key < $1.key }
            .map { FlagSection(title: $0.key, flags: $0.value, hasHeader: true) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                // The grid is a separate, Equatable view so that this view's
                // own state can change while a scroll is in flight without
                // the grid being rebuilt. It used to be inline, and the
                // scroll offset below was stored on every frame; each write
                // re-ran this body and rebuilt the lazy grid mid-scroll. On
                // iPadOS 27 that throws the scroll view back to the top, so
                // the list could not be scrolled at all. App Review saw it on
                // an iPad Air (2026-10-18); it reproduces in the iPadOS 27
                // simulator and does not happen on iOS 26.
                FlagGrid(favourites: favouriteFlags, sections: sections, starred: Set(favourites.ids))
                    .equatable()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                    .safeAreaPadding(.bottom, 56)
                    .background {
                        GeometryReader { geometry in
                            Color.clear.onChange(
                                of: geometry.frame(in: .named(Self.scrollSpace)).minY,
                                initial: true
                            ) { _, y in
                                // Only the threshold crossing is stored, so
                                // the body runs twice per scroll past the
                                // title, not once per frame.
                                let collapsed = y < -Self.largeTitleHeight
                                if collapsed != titleCollapsed { titleCollapsed = collapsed }
                            }
                        }
                    }
            }
            // Must be .coordinateSpace(.named:), not the deprecated
            // .coordinateSpace(name:) — the latter does not pair with
            // .named() and every frame reads back as zero.
            .coordinateSpace(.named(Self.scrollSpace))
            .scrollPosition(id: $topFlag, anchor: .top)
            .navigationTitle(title)
            // Flags are edge-to-edge colour, so a transparent bar leaves the
            // title sitting on top of one. The material is what makes it
            // legible over anything that scrolls underneath.
            .toolbarBackground(.visible, for: .navigationBar)
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

    private static let scrollSpace = "flagGrid"

    /// Roughly what the large title occupies before collapsing into the bar.
    private static let largeTitleHeight: CGFloat = 52

    /// The app's name while the large title is on screen, the continent once it
    /// has collapsed into the bar.
    ///
    /// Both halves matter. Naming the continent while the large title shows
    /// would open the app announcing "Africa" directly above a section header
    /// that also reads "Africa", and it would never say its own name. Keeping
    /// "Flags" forever would waste the inline bar, which is the one place worth
    /// saying where you are once the headers have scrolled past.
    ///
    /// Keyed on whether the title has collapsed rather than on which flag is
    /// at the top. The latter looks equivalent and is not: after scrolling
    /// away and back, the top flag does not reliably return to the first one,
    /// so the title stays stuck on a continent at the top of the list.
    ///
    /// Searching keeps the app's name throughout, since the results are one
    /// flat run with no continent to report.
    private var title: String {
        guard query.isEmpty,
              titleCollapsed,
              let topFlag,
              let group = FlagRegistry.shared.flag(for: topFlag)?.group
        else { return "Flags" }
        return group
    }
}

/// One run of flags under one heading.
struct FlagSection: Equatable, Identifiable {
    let title: String
    let flags: [Flag]
    /// False for search results, which are one flat run with nothing to name.
    let hasHeader: Bool

    var id: String { title }
}

/// The browse grid: favourites first, then each section.
///
/// Equatable, and placed with `.equatable()`, so it is rebuilt only when the
/// flags or the stars change, never because the owner's scroll state did. See
/// `FlagBrowserView.body` for why that matters.
private struct FlagGrid: View, Equatable {
    let favourites: [Flag]
    let sections: [FlagSection]
    let starred: Set<FlagID>

    private static let columns = [GridItem(.adaptive(minimum: 96, maximum: 140), spacing: 16)]

    var body: some View {
        // Headers are deliberately not pinned. A pinned header has to
        // paint its own background, and an opaque one under the
        // translucent navigation bar stamps a hard strip that nothing
        // else on screen matches. Letting them scroll away costs
        // nothing now that the title says which continent you are in.
        LazyVGrid(columns: Self.columns, spacing: 20) {
            if !favourites.isEmpty {
                Section {
                    // favouritesID, not id: the same flag is also
                    // listed under its continent below.
                    ForEach(favourites, id: \.favouritesID) { flag in
                        tile(for: flag)
                    }
                } header: {
                    SectionHeader(title: "Favourites", systemImage: "star.fill")
                }
            }

            ForEach(sections) { section in
                Section {
                    ForEach(section.flags) { flag in
                        tile(for: flag)
                    }
                } header: {
                    if section.hasHeader {
                        SectionHeader(title: section.title, systemImage: "globe")
                    }
                }
            }
        }
        .scrollTargetLayout()
    }

    private func tile(for flag: Flag) -> some View {
        NavigationLink(value: flag) {
            FlagTile(flag: flag, isFavourite: starred.contains(flag.id))
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
    }
}

#Preview {
    FlagBrowserView()
        .environment(Favourites())
}
