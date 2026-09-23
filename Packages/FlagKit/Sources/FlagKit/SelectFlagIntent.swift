import AppIntents

public struct SelectFlagIntent: WidgetConfigurationIntent {
    public static let title: LocalizedStringResource = "Select Flag"
    public static let description = IntentDescription("Choose which flag to show.")

    @Parameter(title: "Flag")
    public var flag: FlagEntity?

    public init() {}

    public init(flag: FlagEntity?) {
        self.flag = flag
    }
}
