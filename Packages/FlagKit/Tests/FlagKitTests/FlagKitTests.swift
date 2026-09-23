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
    #expect(brazil.artwork == .asset(name: "flag-br"))
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

@Test func defaultFlagIsBrazil() throws {
    let flag = try #require(Flag.default)
    #expect(flag.id.code == "br")
}

@Test func entityRoundTripsToItsFlag() throws {
    let brazil = try #require(Flag.default)
    let entity = FlagEntity(flag: brazil)
    #expect(entity.id == "countries/br")
    #expect(entity.flag == brazil)
}

@Test func entityQueryResolvesIdentifiers() async throws {
    let results = try await FlagEntityQuery().entities(for: ["countries/br", "countries/nope"])
    #expect(results.map(\.id) == ["countries/br"])
}

@Test func entityQuerySearchesByName() async throws {
    let results = try await FlagEntityQuery().entities(matching: "braz")
    #expect(results.first?.id == "countries/br")
}

@Test func artworkPrefersABundledAssetAndFallsBackToEmoji() {
    #expect(Countries.artwork(for: "BR") == .asset(name: "flag-br"))
    // Not in the bundled set, so it has to fall back rather than reference a
    // missing asset - Image would render nothing at all.
    #expect(Countries.artwork(for: "zz") == .emoji("\u{1F1FF}\u{1F1FF}"))
}

@Test func everyBundledAssetNameIsReferencedByExactlyOneFlag() {
    let assetNames = Set(Countries.flags.compactMap { flag -> String? in
        if case .asset(let name) = flag.artwork { return name }
        return nil
    })
    // Every flag that claims an asset must name a distinct one.
    let claimed = Countries.flags.filter { if case .asset = $0.artwork { return true } else { return false } }
    #expect(assetNames.count == claimed.count)
    #expect(!assetNames.isEmpty)
}

// MARK: - Regional restrictions

@Test func noFlagIsWithheldGlobally() {
    // Empty by decision, not by oversight. If this ever fails, someone added
    // a global exclusion and should have said why in Countries.excluded.
    #expect(Countries.excluded.isEmpty)
}

@Test func taiwanIsWithheldOnChinaMainland() {
    #expect(Countries.restriction(for: "tw", deviceRegion: "CN") == .withheld)
}

@Test func taiwanIsUnlistedButResolvableInHongKongAndMacao() {
    // Apple hides it from the emoji keyboard there but still renders it, so a
    // complication already configured with it keeps working.
    #expect(Countries.restriction(for: "tw", deviceRegion: "HK") == .unlisted)
    #expect(Countries.restriction(for: "tw", deviceRegion: "MO") == .unlisted)
}

@Test func taiwanIsUnrestrictedEverywhereElse() {
    for region in ["US", "BR", "GB", "JP", "SE", "TW"] {
        #expect(Countries.restriction(for: "tw", deviceRegion: region) == nil, "restricted in \(region)")
    }
}

@Test func restrictionLookupIgnoresCasing() {
    #expect(Countries.restriction(for: "TW", deviceRegion: "cn") == .withheld)
}

@Test func onlyTaiwanIsRestrictedAnywhere() {
    // Guards against the restriction table quietly growing. Every addition is
    // a political call and should be argued for, not slipped in.
    let restricted = Set(Countries.restrictions.values.flatMap(\.keys))
    #expect(restricted == ["tw"])
}

@Test func unlistedFlagsResolveButAreNotOffered() {
    let hidden = Flag(
        id: FlagID(collection: "stub", code: "hh"),
        name: "Hidden",
        artwork: .emoji("H"),
        abbreviation: "HH",
        isListed: false
    )
    struct Stub: FlagCollection {
        static let id = "stub"
        static let displayName = "Stub"
        nonisolated(unsafe) static var flags: [Flag] = []
    }
    Stub.flags = [hidden]
    let registry = FlagRegistry(collections: [Stub.self])

    #expect(registry.flag(for: hidden.id) == hidden)   // still resolves
    #expect(registry.listedFlags.isEmpty)              // not offered
    #expect(registry.search("hidden").isEmpty)         // not searchable
    #expect(registry.search("").isEmpty)               // not suggested
}

@Test func palestineKosovoAndWesternSaharaAllShip() {
    // Present in the system region list and in flag-icons. Shipping the
    // standard list rather than curating it is the whole position.
    for code in ["ps", "il", "xk", "eh"] {
        #expect(FlagRegistry.shared.flag(for: FlagID(collection: "countries", code: code)) != nil, "missing \(code)")
    }
}

@Test func chinaMainlandBuildOmitsTaiwanEntirely() {
    let codes = Countries.build(deviceRegion: "CN").map(\.id.code)
    #expect(!codes.contains("tw"))
    #expect(codes.contains("cn"))
    #expect(codes.contains("hk"))
}

@Test func hongKongBuildKeepsTaiwanButUnlisted() throws {
    let flags = Countries.build(deviceRegion: "HK")
    let taiwan = try #require(flags.first { $0.id.code == "tw" })
    #expect(taiwan.isListed == false)
}

@Test func unrestrictedRegionBuildListsTaiwanNormally() throws {
    let taiwan = try #require(Countries.build(deviceRegion: "BR").first { $0.id.code == "tw" })
    #expect(taiwan.isListed)
}

@Test func onlyTaiwanDiffersBetweenRegionBuilds() {
    // The restriction table should change exactly one flag, nothing else.
    let open = Set(Countries.build(deviceRegion: "BR").map(\.id.code))
    let china = Set(Countries.build(deviceRegion: "CN").map(\.id.code))
    #expect(open.subtracting(china) == ["tw"])
    #expect(china.subtracting(open).isEmpty)
}
