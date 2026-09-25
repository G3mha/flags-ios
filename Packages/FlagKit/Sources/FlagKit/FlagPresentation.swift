import AppIntents

/// How much of the widget the flag should occupy.
///
/// A circular slot masks its content to a circle regardless, so this is really
/// a choice about composition: keep the flag as a contained shape with room
/// around it, or let it run to the edges and be cropped.
public enum FlagPresentation: String, AppEnum, Sendable {
    /// A circle, with the widget's own background showing around it. In a
    /// rectangular widget this sits the flag beside the country's name.
    case circle
    /// Edge to edge, cropped to whatever shape the slot is. No name, no
    /// background — just flag.
    case fill

    public static let typeDisplayRepresentation = TypeDisplayRepresentation("Shape")

    public static let caseDisplayRepresentations: [FlagPresentation: DisplayRepresentation] = [
        .circle: DisplayRepresentation(
            title: "Circle",
            subtitle: "A round flag, with the name alongside where there is room"
        ),
        .fill: DisplayRepresentation(
            title: "Fill",
            subtitle: "Edge to edge, cropped to fit"
        ),
    ]
}
