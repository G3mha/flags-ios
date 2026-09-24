import FlagKit
import SwiftUI

/// A flag as it appears in the browse grid.
///
/// The hairline stroke matters more than it looks: a good number of flags run
/// white to their edge — Japan, Finland, Nigeria — and without it they bleed
/// into a light background and stop reading as a flag at all.
struct FlagTile: View {
    let flag: Flag
    var isFavourite = false

    var body: some View {
        VStack(spacing: 8) {
            FlagArtwork(flag: flag, cornerRadius: 14)
                .overlay(alignment: .topTrailing) {
                    if isFavourite {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .padding(5)
                            .background(.black.opacity(0.45), in: .circle)
                            .padding(6)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

            Text(flag.name)
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isFavourite ? "\(flag.name), favourite" : flag.name)
    }
}

/// The artwork on its own, squared off and outlined.
struct FlagArtwork: View {
    let flag: Flag
    var cornerRadius: CGFloat = 14

    var body: some View {
        FlagView(flag: flag, shape: .roundedRect(cornerRadius: cornerRadius))
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(.separator, lineWidth: 0.5)
            }
    }
}
