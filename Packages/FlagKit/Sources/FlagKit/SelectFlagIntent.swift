import AppIntents

public struct SelectFlagIntent: WidgetConfigurationIntent {
    public static let title: LocalizedStringResource = "Select Flag"
    public static let description = IntentDescription("Choose which flag to show, and how much of the widget it fills.")

    @Parameter(title: "Flag")
    public var flag: FlagEntity?

    @Parameter(title: "Shape", default: .circle)
    public var presentation: FlagPresentation

    public init() {}

    public init(flag: FlagEntity?, presentation: FlagPresentation = .circle) {
        self.flag = flag
        self.presentation = presentation
    }
}
