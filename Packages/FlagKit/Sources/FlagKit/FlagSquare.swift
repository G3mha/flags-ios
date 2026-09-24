import SwiftUI

/// A flag drawn as a rounded square, outlined.
///
/// Named apart from `FlagArtwork`, which describes how artwork is obtained
/// rather than how it is drawn.
///
/// The hairline stroke is not decoration. A good number of flags run white to
/// their edge — Japan, Finland, Nigeria — and without it they dissolve into a
/// light background and stop reading as a flag at all.
public struct FlagSquare: View {
    private let flag: Flag
    private let cornerRadius: CGFloat

    public init(flag: Flag, cornerRadius: CGFloat = 14) {
        self.flag = flag
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        FlagView(flag: flag, shape: .roundedRect(cornerRadius: cornerRadius))
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(.separator, lineWidth: 0.5)
            }
    }
}
