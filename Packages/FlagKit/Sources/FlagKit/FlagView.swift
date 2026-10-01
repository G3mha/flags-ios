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
    private let inWidget: Bool

    @Environment(\.displayScale) private var displayScale

    /// - Parameter inWidget: true when this is drawn inside a widget or a
    ///   complication, where the size of an image is capped. See `fitted`.
    public init(flag: Flag, shape: FlagShape = .circle, inWidget: Bool = false) {
        self.flag = flag
        self.shape = shape
        self.inWidget = inWidget
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
            if let image = UIImage(named: name) {
                if inWidget {
                    GeometryReader { proxy in
                        // No size yet means nothing to fit to, and handing
                        // over the full-size artwork is the one thing a widget
                        // must not do.
                        if proxy.size.width > 0, proxy.size.height > 0 {
                            bitmap(Self.fitted(image, to: proxy.size, scale: displayScale))
                                .frame(width: proxy.size.width, height: proxy.size.height)
                        }
                    }
                } else {
                    bitmap(image)
                }
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

    /// The pixel size to draw artwork at so that it covers a slot.
    ///
    /// The slot's own size in pixels, with the same proportions, so the result
    /// covers it the way `scaledToFill` would. Never larger than the artwork:
    /// a Home Screen widget at 3x asks for more pixels than a 384px flag has,
    /// and inventing them helps nobody.
    ///
    /// Kept apart from the drawing so it can be tested on the macOS host,
    /// where there is no UIKit.
    static func bitmapSize(covering slot: CGSize, scale: CGFloat, source: CGSize) -> CGSize {
        guard slot.width > 0, slot.height > 0, source.width > 0, source.height > 0 else { return .zero }
        var width = (slot.width * scale).rounded(.up)
        var height = (slot.height * scale).rounded(.up)

        // How far the artwork would have to grow to cover the slot. Above 1
        // the slot wants more pixels than there are, so shrink the target.
        let cover = max(width / source.width, height / source.height)
        if cover > 1 {
            width = max(1, (width / cover).rounded(.down))
            height = max(1, (height / cover).rounded(.down))
        }
        return CGSize(width: width, height: height)
    }

    #if canImport(UIKit)
    /// Redraws the artwork at the size it is about to be shown, in pixels.
    ///
    /// WidgetKit archives a widget's view and refuses any image much larger
    /// than the widget itself: the limit is the widget's pixel area times 1.44.
    /// The catalogue ships 384px squares, which suits a Home Screen widget at
    /// 3x and is ten times too big for a 51pt complication. The refusal is
    /// logged as a fault and nothing else happens, so the face keeps showing
    /// the redacted placeholder, which is a plain disc:
    ///
    ///     Widget archival failed due to image being too large [1] -
    ///     (384, 384), totalArea: 147456 > max[14981.760000]
    ///
    /// The view still renders, the timeline still arrives and the bitmap still
    /// holds the right pixels, which is why this looked like everything except
    /// a size problem. It was once put down to asset-catalogue images not
    /// drawing in a watch extension, and "fixed" by redrawing them at full
    /// size, which changed nothing. It reproduces in the simulator, where the
    /// fault can be read with `simctl spawn <device> log show`.
    ///
    /// Drawing at exactly the slot's size stays inside the limit for every
    /// family and every watch, since the bitmap can never have more pixels
    /// than the widget does.
    static func fitted(_ image: UIImage, to slot: CGSize, scale: CGFloat) -> UIImage {
        guard let source = image.cgImage else { return image }
        let sourceSize = CGSize(width: source.width, height: source.height)
        let size = bitmapSize(covering: slot, scale: scale, source: sourceSize)

        guard size.width >= 1, size.height >= 1,
              let context = CGContext(
                data: nil,
                width: Int(size.width),
                height: Int(size.height),
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
              )
        else { return image }

        // Centred and cropped, as scaledToFill would.
        let fill = max(size.width / sourceSize.width, size.height / sourceSize.height)
        let drawn = CGSize(width: sourceSize.width * fill, height: sourceSize.height * fill)
        context.interpolationQuality = .high
        context.draw(source, in: CGRect(
            x: (size.width - drawn.width) / 2,
            y: (size.height - drawn.height) / 2,
            width: drawn.width,
            height: drawn.height
        ))
        return context.makeImage().map(UIImage.init(cgImage:)) ?? image
    }

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
