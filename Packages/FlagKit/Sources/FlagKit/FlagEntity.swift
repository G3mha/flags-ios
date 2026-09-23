import AppIntents

/// A flag as the widget configuration editor sees it.
///
/// `EntityStringQuery` rather than a plain query because the countries
/// collection alone is ~250 entries: without search, picking one on a watch
/// means scrolling forever.
public struct FlagEntity: AppEntity, Sendable {
    public let id: String
    public let name: String

    public init(flag: Flag) {
        self.id = flag.id.rawValue
        self.name = flag.name
    }

    public static var typeDisplayRepresentation: TypeDisplayRepresentation { "Flag" }
    public static let defaultQuery = FlagEntityQuery()

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    /// The domain object behind this entity, or nil if the collection that
    /// owned it has gone away since the complication was configured.
    public var flag: Flag? {
        FlagID(rawValue: id).flatMap { FlagRegistry.shared.flag(for: $0) }
    }
}

public struct FlagEntityQuery: EntityStringQuery, Sendable {
    public init() {}

    public func entities(for identifiers: [String]) async throws -> [FlagEntity] {
        identifiers
            .compactMap(FlagID.init(rawValue:))
            .compactMap(FlagRegistry.shared.flag(for:))
            .map(FlagEntity.init(flag:))
    }

    public func entities(matching string: String) async throws -> [FlagEntity] {
        FlagRegistry.shared.search(string).map(FlagEntity.init(flag:))
    }

    public func suggestedEntities() async throws -> [FlagEntity] {
        FlagRegistry.shared.allFlags.map(FlagEntity.init(flag:))
    }

    public func defaultResult() async -> FlagEntity? {
        Flag.default.map(FlagEntity.init(flag:))
    }
}

extension Flag {
    /// Brazil. This app exists because someone wanted to see it from abroad.
    public static var `default`: Flag? {
        FlagRegistry.shared.flag(for: FlagID(collection: Countries.id, code: "br"))
    }
}
