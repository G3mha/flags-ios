import AppIntents

public struct SelectFlagIntent: WidgetConfigurationIntent {
    public static let title: LocalizedStringResource = "Select Flag"
    public static let description = IntentDescription("Choose which flag to show, how much of the widget it fills, and how loudly it is drawn.")

    @Parameter(title: "Flag")
    public var flag: FlagEntity?

    @Parameter(title: "Shape", default: .circle)
    public var presentation: FlagPresentation

    // A default, so a widget configured before this parameter existed keeps
    // working: a stored intent without it decodes to full colour.
    @Parameter(title: "Style", default: .colour)
    public var style: FlagStyle

    public init() {}

    public init(flag: FlagEntity?, presentation: FlagPresentation = .circle, style: FlagStyle = .colour) {
        self.flag = flag
        self.presentation = presentation
        self.style = style
    }
}
