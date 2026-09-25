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

    /// Always the artwork.
    ///
    /// This used to swap in the country code whenever the mode was not
    /// fullColor, on the assumption that a flattened flag would be an
    /// unreadable blob. That was wrong, and it made every iOS Lock Screen
    /// accessory - which is always vibrant - show two letters instead of a
    /// flag. Desaturating Brazil still leaves a light diamond on mid grey with
    /// a dark disc, which reads as a flag; "BR" does not.
    ///
    /// The code is still the fallback for artwork that cannot be loaded at all,
    /// which is a different problem.
    @ViewBuilder private var content: some View {
        artwork
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
            if let image = UIImage(named: name).map(renderable) {
                bitmap(image)
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

    #if os(watchOS)
    /// Redraws an asset-catalogue image into a plain bitmap.
    ///
    /// A watchOS widget extension draws nothing at all for an image that came
    /// from an asset catalogue. The image is there — `UIImage(named:)` returns
    /// it — but SwiftUI renders empty, which is why the complication was blank
    /// while the app showed the same flag fine.
    ///
    /// Not a size problem, though it looks like one at first: a 64px image
    /// drawn in code renders, and so does this same 384px flag once it has been
    /// through a CGContext. What matters is that the bitmap is concrete rather
    /// than whatever deferred representation the catalogue hands back.
    ///
    /// iOS has no such trouble, so it keeps the image untouched.
    private func renderable(_ image: UIImage) -> UIImage {
        guard let source = image.cgImage,
              let context = CGContext(
                data: nil,
                width: source.width,
                height: source.height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
              )
        else { return image }
        context.interpolationQuality = .high
        context.draw(source, in: CGRect(x: 0, y: 0, width: source.width, height: source.height))
        return context.makeImage().map(UIImage.init(cgImage:)) ?? image
    }
    #elseif canImport(UIKit)
    private func renderable(_ image: UIImage) -> UIImage { image }
    #endif

    #if canImport(UIKit)
    /// `widgetAccentedRenderingMode` keeps the colour where the system is only
    /// tinting rather than fully desaturating, such as a tinted Home Screen.
    /// It arrived after this package's minimum, hence the branch.
    @ViewBuilder private func bitmap(_ image: UIImage) -> some View {
        if #available(iOS 18, watchOS 11, *) {
            Image(uiImage: image)
                .resizable()
                .widgetAccentedRenderingMode(.fullColor)
                .scaledToFill()
        } else {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        }
    }
    #endif

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
