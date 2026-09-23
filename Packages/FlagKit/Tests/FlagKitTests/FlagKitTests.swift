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

@Test func emojiDerivesFromISOCode() {
    #expect(Countries.emoji(for: "BR") == "🇧🇷")
    #expect(Countries.emoji(for: "jp") == "🇯🇵")
}

@Test func countriesIncludeBrazilWithAnAbbreviation() throws {
    let brazil = try #require(FlagRegistry.shared.flag(for: FlagID(collection: "countries", code: "br")))
    #expect(brazil.abbreviation == "BR")
    #expect(brazil.artwork == .emoji("🇧🇷"))
}

@Test func countryListIsPlausiblySized() {
    // Derived from Locale rather than a table we own, so this guards against
    // an OS change quietly emptying or exploding the list.
    let count = Countries.flags.count
    #expect(count > 200, "only \(count) countries")
    #expect(count < 400, "\(count) countries is more than ISO 3166-1 has")
}

@Test func everyFlagHasDistinctID() {
    let all = FlagRegistry.shared.allFlags
    #expect(Set(all.map(\.id)).count == all.count)
}

@Test func flagsAreSortedByName() {
    let names = Countries.flags.map(\.name)
    #expect(names == names.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending })
}
