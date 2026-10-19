import AppIntents
import SwiftUI

/// How loudly the flag is drawn.
///
/// A flag is a block of saturated colour, and on a Home Screen or a watch face
/// that can shout. The Lock Screen's own treatment, which renders every widget
/// as a translucent monochrome shape, is what people reach for when they want
/// the flag present but quiet; these give the same choice where the system
/// does not make it for them.
///
/// What "translucent" shows through depends on the slot. A watch face's
/// complication has no background of its own, so the face shows through the
/// flag. A Home Screen widget always sits on the tile the system gives it (a
/// clear container background is drawn as the default one, not as the
/// wallpaper), so there the flag reads as pale rather than see-through.
///
/// Stored in widget configuration by raw value, so the names are fixed.
public enum FlagStyle: String, AppEnum, Sendable {
    /// As drawn.
    case colour
    /// The same shapes, with most of the colour taken out.
    case muted
    /// The same shapes in black and white.
    case greyscale
    /// In colour, but half see-through.
    case translucent

    public static let typeDisplayRepresentation = TypeDisplayRepresentation("Style")

    public static let caseDisplayRepresentations: [FlagStyle: DisplayRepresentation] = [
        .colour: DisplayRepresentation(
            title: "Full colour",
            subtitle: "The flag as it is"
        ),
        .muted: DisplayRepresentation(
            title: "Muted",
            subtitle: "Softer colours that sit back"
        ),
        .greyscale: DisplayRepresentation(
            title: "Greyscale",
            subtitle: "Black and white"
        ),
        .translucent: DisplayRepresentation(
            title: "Translucent",
            subtitle: "Half see-through"
        ),
    ]

    /// For a line like "Japan, greyscale" in the watch's picker.
    public var name: String {
        switch self {
        case .colour: "full colour"
        case .muted: "muted"
        case .greyscale: "greyscale"
        case .translucent: "translucent"
        }
    }

    /// How much of the colour survives. 1 is untouched.
    ///
    /// Greyscale is not saturation 0: a widget archived with that drew in
    /// full colour on iOS 27 (the simulator showed it; the timeline logged
    /// no error), while 0.35 took. It goes through `grayscale(1)` instead.
    var saturation: Double {
        switch self {
        case .colour, .greyscale, .translucent: 1
        case .muted: 0.35
        }
    }

    /// How far towards black and white. 1 is all the way.
    var grey: Double {
        switch self {
        case .greyscale: 1
        case .colour, .muted, .translucent: 0
        }
    }

    /// How much of the flag is let through. 1 is opaque.
    var opacity: Double {
        switch self {
        case .colour, .muted, .greyscale: 1
        case .translucent: 0.45
        }
    }
}

extension View {
    /// Draws the view in the given style.
    func flagStyle(_ style: FlagStyle) -> some View {
        saturation(style.saturation).grayscale(style.grey).opacity(style.opacity)
    }
}
