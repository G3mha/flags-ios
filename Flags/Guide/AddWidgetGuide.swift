import SwiftUI

/// How to actually get a flag onto a watch face, Lock Screen or Home Screen.
///
/// Widget configuration happens in the system's own editors, not in here, so
/// the honest thing is to say where to go rather than pretend the app can do
/// it. Written as plain steps because that is what people follow.
struct AddWidgetGuide: View {
    var compact = false

    private static let places: [Place] = [
        Place(
            title: "Apple Watch face",
            systemImage: "applewatch",
            steps: [
                "Press and hold your watch face, then tap Edit.",
                "Swipe to Complications and tap a slot.",
                "Choose Flags, then pick your flag.",
            ]
        ),
        Place(
            title: "Lock Screen",
            systemImage: "lock.iphone",
            steps: [
                "Press and hold the Lock Screen, then tap Customise.",
                "Tap the area under the clock.",
                "Choose Flags and pick your flag.",
            ]
        ),
        Place(
            title: "Home Screen",
            systemImage: "square.grid.2x2",
            steps: [
                "Press and hold the Home Screen, then tap Edit.",
                "Tap Add Widget and search for Flags.",
                "Add it, then touch and hold to pick your flag.",
            ]
        ),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if compact {
                Text("Put this flag somewhere")
                    .font(.headline)
            }

            ForEach(Self.places) { place in
                PlaceCard(place: place)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(compact ? 0 : 20)
        .navigationTitle(compact ? "" : "Adding a flag")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct Place: Identifiable {
    let title: String
    let systemImage: String
    let steps: [String]
    var id: String { title }
}

private struct PlaceCard: View {
    let place: Place

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(place.title, systemImage: place.systemImage)
                .font(.subheadline.weight(.semibold))

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(place.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 18, height: 18)
                            .background(.tint, in: .circle)
                        Text(step)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.4), in: .rect(cornerRadius: 16))
    }
}

#Preview {
    NavigationStack { ScrollView { AddWidgetGuide() } }
}
