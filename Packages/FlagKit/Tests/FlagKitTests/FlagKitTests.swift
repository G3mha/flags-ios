import Testing
@testable import FlagKit

@Test func flagIDRoundTripsThroughRawValue() {
    let id = FlagID(collection: "countries", code: "BR")
    #expect(id.rawValue == "countries/br")
    #expect(FlagID(rawValue: "countries/br") == id)
    #expect(FlagID(rawValue: "nope") == nil)
}

@Test func codeIsCaseInsensitive() {
    #expect(FlagID(collection: "countries", code: "BR") == FlagID(collection: "countries", code: "br"))
}

@Test func registryResolvesUnknownIDsToNil() {
    #expect(FlagRegistry.shared.flag(for: FlagID(collection: "clubs", code: "zz")) == nil)
}

@Test func searchPrefersPrefixMatchesOverContainedOnes() {
    struct Stub: FlagCollection {
        static let id = "stub"
        static let displayName = "Stub"
        static let flags = [
            Flag(id: FlagID(collection: "stub", code: "gi"), name: "Gibraltar", artwork: .emoji("A"), abbreviation: "GI"),
            Flag(id: FlagID(collection: "stub", code: "br"), name: "Brazil", artwork: .emoji("B"), abbreviation: "BR"),
        ]
    }
    let registry = FlagRegistry(collections: [Stub.self])
    #expect(registry.search("bra").map(\.id.code) == ["br", "gi"])
}
