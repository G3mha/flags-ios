import SwiftUI

/// The four ways we might draw a flag in a complication. The spike exists to find
/// out which of these survives the watch face's rendering mode with its colours intact.
enum FlagVariant: String, CaseIterable {
    case asset          = "Asset"
    case assetAccented  = "Asset+FC"
    case emoji          = "Emoji"
    case shapes         = "Shapes"

    /// Single letter burned into the corner so a screenshot identifies the slot.
    var tag: String {
        switch self {
        case .asset:         "A"
        case .assetAccented: "B"
        case .emoji:         "C"
        case .shapes:        "D"
        }
    }
}

/// Brazil drawn with SwiftUI primitives, official 20x14 geometry normalised to a square.
struct BrazilShapes: View {
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let u = s / 20
            let c = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let r = 3.5 * u

            ZStack {
                Color(red: 0.0, green: 0.608, blue: 0.282)

                Path { p in
                    p.move(to: CGPoint(x: c.x - 8.3 * u, y: c.y))
                    p.addLine(to: CGPoint(x: c.x, y: c.y - 5.3 * u))
                    p.addLine(to: CGPoint(x: c.x + 8.3 * u, y: c.y))
                    p.addLine(to: CGPoint(x: c.x, y: c.y + 5.3 * u))
                    p.closeSubpath()
                }
                .fill(Color(red: 1.0, green: 0.867, blue: 0.0))

                Circle()
                    .fill(Color(red: 0.0, green: 0.157, blue: 0.494))
                    .frame(width: 2 * r, height: 2 * r)
                    .position(c)

                // Banner, clipped to the disc
                Capsule()
                    .fill(.white)
                    .frame(width: 2 * r, height: r * 0.34)
                    .rotationEffect(.degrees(-12))
                    .position(x: c.x, y: c.y - r * 0.42)
                    .clipShape(Circle().path(in: CGRect(x: c.x - r, y: c.y - r,
                                                        width: 2 * r, height: 2 * r)))
            }
        }
    }
}

/// Renders one variant and, where there is room, labels it with the rendering mode
/// the system actually handed us.
struct FlagSpikeView: View {
    let variant: FlagVariant
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.widgetFamily) private var family

    private var modeName: String {
        switch mode {
        case .fullColor: "full"
        case .accented:  "accent"
        case .vibrant:   "vibrant"
        default:         "?"
        }
    }

    @ViewBuilder private var artwork: some View {
        switch variant {
        case .asset:
            Image("flag-br").resizable().scaledToFill()
        case .assetAccented:
            Image("flag-br").resizable()
                .widgetAccentedRenderingMode(.fullColor)
                .scaledToFill()
        case .emoji:
            Text(verbatim: "🇧🇷").font(.system(size: 200)).minimumScaleFactor(0.01)
        case .shapes:
            BrazilShapes()
        }
    }

    var body: some View {
        switch family {
        case .accessoryRectangular:
            HStack(spacing: 6) {
                artwork.frame(width: 38, height: 38).clipShape(.rect(cornerRadius: 5))
                VStack(alignment: .leading) {
                    Text(variant.rawValue).font(.headline)
                    Text(modeName).font(.caption2)
                }
                Spacer(minLength: 0)
            }
        case .accessoryInline:
            Text("\(variant.rawValue) \(modeName)")
        default:
            artwork.clipShape(.circle)
        }
    }
}
