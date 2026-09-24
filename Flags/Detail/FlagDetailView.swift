import FlagKit
import SwiftUI

struct FlagDetailView: View {
    let flag: Flag

    @Environment(Favourites.self) private var favourites

    private var isFavourite: Bool { favourites.contains(flag.id) }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                FlagSquare(flag: flag, cornerRadius: 28)
                    .frame(maxWidth: 260)
                    .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
                    .padding(.top, 8)

                VStack(spacing: 6) {
                    Text(flag.name)
                        .font(.title2.weight(.semibold))
                        .multilineTextAlignment(.center)

                    Text(flag.abbreviation)
                        .font(.footnote.weight(.medium))
                        .monospaced()
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.quaternary, in: .capsule)
                }

                // The point of the app. Browsing is how you find a flag; this
                // is how it ends up somewhere you will actually see it.
                AddWidgetGuide(compact: true)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .navigationTitle(flag.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.snappy) { favourites.toggle(flag.id) }
                } label: {
                    Label(
                        isFavourite ? "Remove from favourites" : "Add to favourites",
                        systemImage: isFavourite ? "star.fill" : "star"
                    )
                }
                .sensoryFeedback(.selection, trigger: isFavourite)
            }
        }
    }
}

#Preview {
    NavigationStack {
        FlagDetailView(flag: .default!)
    }
    .environment(Favourites())
}
