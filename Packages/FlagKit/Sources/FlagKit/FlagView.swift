import SwiftUI
import WidgetKit

#if canImport(UIKit)
import UIKit
#endif

public enum FlagShape: Sendable {
    /// Circular complication slots and Lock Screen accessories.
    case circle
    /// Home Screen widgets and in-app lists.
    case roundedRect(cornerRadius: CGFloat)
    /// No clipping.
    case natural
}

/// Draws a flag, adapting to whatever rendering mode the system hands us.
///
/// The spike in `Spike/` established that Infograph's circular sub-dials give
/// third-party complications `fullColor`, so the real artwork survives there.
/// Other faces, and every iOS Lock Screen accessory, use `accented` or
/// `vibrant`: the system flattens the view into flatly-coloured groups and the
/// flag's colours are gone. A flattened flag is an unreadable blob, so those
/// modes get the country code instead — which stays legible at 30 points.
public struct FlagView: View {
    private let flag: Flag
    private let shape: FlagShape

    @Environment(\.widgetRenderingMode) private var renderingMode

    public init(flag: Flag, shape: FlagShape = .circle) {
        self.flag = flag
        self.shape = shape
    }

    public var body: some View {
        content
            .clipShape(clipShape)
    }

    @ViewBuilder private var content: some View {
        if renderingMode == .fullColor {
            artwork
        } else {
            flattened
        }
    }

    @ViewBuilder private var artwork: some View {
        switch flag.artwork {
        case .emoji(let string):
            // Scaled up then shrunk to fit: emoji have no resizable form, and
            // an oversized base size keeps them sharp in the larger families.
            Text(verbatim: string)
                .font(.system(size: 200))
                .minimumScaleFactor(0.01)
                .lineLimit(1)
        case .asset(let name):
            // The catalogue lives in each target's own bundle rather than in a
            // package resource bundle, so this resolves through Bundle.main.
            //
            // It used to be an SPM resource, and Image(_:bundle: .module)
            // rendered nothing inside a widget extension - the catalogue was
            // present and Bundle.module resolved, but nothing drew. Moving it
            // into the targets removes that whole failure mode.
            //
            // The fallback stays regardless: a complication that cannot load
            // its artwork should read as a country rather than render nothing.
            // UIKit is absent on the macOS host the package's tests run on, so
            // that build keeps the plain SwiftUI path.
            #if canImport(UIKit)
            if let image = UIImage(named: name) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                flattened
            }
            #else
            Image(name)
                .resizable()
                .scaledToFill()
            #endif
        }
    }

    private var flattened: some View {
        Text(flag.abbreviation)
            .font(.system(size: 200, weight: .semibold, design: .rounded))
            .minimumScaleFactor(0.01)
            .lineLimit(1)
            .widgetAccentable()
    }

    private var clipShape: AnyShape {
        switch shape {
        case .circle:                     AnyShape(Circle())
        case .roundedRect(let radius):    AnyShape(RoundedRectangle(cornerRadius: radius))
        case .natural:                    AnyShape(Rectangle())
        }
    }
}
