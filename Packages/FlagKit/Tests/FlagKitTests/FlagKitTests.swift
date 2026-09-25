import Foundation
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

// MARK: - Unpopulated duplicates

@Test func unpopulatedDependenciesAreNotOffered() {
    // Each of these draws its parent's flag, so listing it repeats a picture
    // already in the grid. Bouvet Island showing Norway's flag is correct and
    // still looks like a bug to anyone scrolling past it.
    let codes = Set(Countries.flags.map { $0.id.code.lowercased() })
    for dropped in Countries.uninhabited {
        #expect(!codes.contains(dropped), "\(dropped) should not be listed")
    }
}

@Test func inhabitedDependenciesSurviveEvenWhenTheyShareAFlag() {
    // The line is population, not duplication. People live in these, and they
    // should be able to pick where they are from.
    let codes = Set(Countries.flags.map { $0.id.code.lowercased() })
    for kept in ["sj", "re", "yt", "gp", "gf", "pm", "wf", "bl", "mf", "bq"] {
        #expect(codes.contains(kept), "\(kept) should still be listed")
    }
}

@Test func theTwoTrimmingSetsStayDistinct() {
    // Dropping an unpopulated duplicate is not a political exclusion. If these
    // ever overlap, one rule is being used to do the other's job.
    #expect(Countries.excluded.isDisjoint(with: Countries.uninhabited))
}

@Test func trimmedCodesAreLowercasedLikeTheRestOfTheFile() {
    // isoRegions hands back "BV". A set keyed "BV" would silently match
    // nothing once the comparison lowercases, so the convention is worth
    // holding to.
    #expect(Countries.uninhabited.allSatisfy { $0 == $0.lowercased() })
    #expect(Countries.excluded.allSatisfy { $0 == $0.lowercased() })
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

// MARK: - Favourites

private func makeDefaults() -> UserDefaults {
    let d = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
    d.removePersistentDomain(forName: d.description)
    return d
}

/// Device-local only; the cloud store is a shared singleton and has no place
/// in a unit test.
@MainActor private func makeFavourites(_ defaults: UserDefaults = makeDefaults()) -> Favourites {
    Favourites(local: defaults, cloud: nil)
}

@MainActor @Test func favouritesStartEmptyAndToggle() {
    let favourites = makeFavourites()
    let br = FlagID(collection: "countries", code: "br")
    #expect(favourites.ids.isEmpty)
    favourites.toggle(br)
    #expect(favourites.contains(br))
    favourites.toggle(br)
    #expect(!favourites.contains(br))
}

@MainActor @Test func newestFavouriteComesFirst() {
    let favourites = makeFavourites()
    let br = FlagID(collection: "countries", code: "br")
    let jp = FlagID(collection: "countries", code: "jp")
    favourites.toggle(br)
    favourites.toggle(jp)
    #expect(favourites.ids == [jp, br])
}

@MainActor @Test func favouritesPersistAcrossInstances() {
    let defaults = makeDefaults()
    let br = FlagID(collection: "countries", code: "br")
    makeFavourites(defaults).toggle(br)
    #expect(makeFavourites(defaults).contains(br))
}

@MainActor @Test func unstarringPersistsRatherThanLookingAbsent() {
    // The distinction the timestamps exist for: a flag that was deliberately
    // unstarred must not read the same as one never heard of.
    let defaults = makeDefaults()
    let br = FlagID(collection: "countries", code: "br")
    let first = makeFavourites(defaults)
    first.toggle(br)
    first.toggle(br)
    #expect(!makeFavourites(defaults).contains(br))
}

@MainActor @Test func unknownFavouritesAreDroppedWhenResolved() {
    let favourites = makeFavourites()
    favourites.toggle(FlagID(collection: "countries", code: "br"))
    favourites.toggle(FlagID(collection: "clubs", code: "gone"))
    #expect(favourites.ids.count == 2)
    #expect(favourites.flags().map { $0.id.code } == ["br"])
}

// MARK: - Gallery recommendations

private func id(_ code: String) -> FlagID { FlagID(collection: "countries", code: code) }

@Test func favouritesLeadTheGallery() {
    // The whole point: star a flag on the phone, it syncs, and the watch's
    // complication gallery offers it.
    let flags = FlagTimelineProvider.suggestedFlags(
        favourites: [id("jp"), id("pt")],
        deviceRegion: "US"
    )
    #expect(flags.prefix(2).map { $0.id.code } == ["jp", "pt"])
}

@Test func theDeviceRegionFollowsTheFavourites() {
    let flags = FlagTimelineProvider.suggestedFlags(favourites: [id("jp")], deviceRegion: "US")
    #expect(flags.map { $0.id.code }.contains("us"))
    #expect(flags.first?.id.code == "jp")
}

@Test func withNoFavouritesTheRegionStillLeads() {
    let flags = FlagTimelineProvider.suggestedFlags(favourites: [], deviceRegion: "US")
    #expect(flags.first?.id.code == "us")
}

@Test func nothingIsOfferedTwice() {
    // A Brazilian who has starred Brazil should see it once, not three times
    // over: favourite, device region, and default all resolve to it.
    let flags = FlagTimelineProvider.suggestedFlags(favourites: [id("br")], deviceRegion: "BR")
    #expect(flags.map { $0.id.code } == ["br"])
}

@Test func theGalleryIsCapped() {
    // The cap has to bite somewhere, but on the watch anything cut cannot go
    // on a face at all, so it is set well above a realistic set of favourites.
    let many = Countries.flags.prefix(60).map(\.id)
    let flags = FlagTimelineProvider.suggestedFlags(
        favourites: Array(many), deviceRegion: "US"
    )
    #expect(flags.count == FlagTimelineProvider.maxRecommendations)
    #expect(FlagTimelineProvider.maxRecommendations >= 25)
}

// MARK: - Recently opened

@Test func openingAFlagMakesItOfferableWithoutStarringIt() {
    // The point of recents. On the watch the picker shows recommendations and
    // nothing else, so without this a flag must be starred to reach a face.
    let flags = FlagTimelineProvider.suggestedFlags(
        favourites: [], recents: [id("jp")], deviceRegion: "US"
    )
    #expect(flags.map { $0.id.code }.contains("jp"))
}

@Test func favouritesOutrankRecents() {
    let flags = FlagTimelineProvider.suggestedFlags(
        favourites: [id("br")], recents: [id("jp")], deviceRegion: "US"
    )
    #expect(flags.first?.id.code == "br")
}

@Test func aFlagBothStarredAndRecentAppearsOnce() {
    let flags = FlagTimelineProvider.suggestedFlags(
        favourites: [id("jp")], recents: [id("jp")], deviceRegion: nil
    )
    #expect(flags.filter { $0.id.code == "jp" }.count == 1)
}

@Test func recentsAreNewestFirst() {
    let defaults = makeDefaults()
    Recents.record(id("br"), in: defaults)
    Recents.record(id("jp"), in: defaults)
    #expect(Recents.ids(in: defaults) == [id("jp"), id("br")])
}

@Test func openingAFlagAgainMovesItUpRatherThanDuplicating() {
    let defaults = makeDefaults()
    Recents.record(id("br"), in: defaults)
    Recents.record(id("jp"), in: defaults)
    Recents.record(id("br"), in: defaults)
    #expect(Recents.ids(in: defaults) == [id("br"), id("jp")])
}

@Test func recentsStopGrowing() {
    let defaults = makeDefaults()
    for code in Countries.flags.prefix(Recents.limit + 10).map(\.id.code) {
        Recents.record(id(code), in: defaults)
    }
    #expect(Recents.ids(in: defaults).count == Recents.limit)
}

@Test func recentsStartEmpty() {
    #expect(Recents.ids(in: makeDefaults()).isEmpty)
}

@Test func unknownFavouritesAreSkippedRatherThanBlanking() {
    // A flag from a pack that is gone must not cost the gallery a slot.
    let flags = FlagTimelineProvider.suggestedFlags(
        favourites: [FlagID(collection: "clubs", code: "gone"), id("jp")],
        deviceRegion: nil
    )
    #expect(flags.first?.id.code == "jp")
}

@MainActor @Test func storedIDsReadsWhatWasStarred() {
    let defaults = makeDefaults()
    let favourites = Favourites(local: defaults, cloud: nil)
    favourites.toggle(id("br"))
    favourites.toggle(id("jp"))

    // Newest first, matching the order the gallery shows them in.
    #expect(Favourites.storedIDs(in: defaults) == [id("jp"), id("br")])
}

@MainActor @Test func storedIDsIgnoresUnstarredFlags() {
    let defaults = makeDefaults()
    let favourites = Favourites(local: defaults, cloud: nil)
    favourites.toggle(id("br"))
    favourites.toggle(id("br"))
    #expect(Favourites.storedIDs(in: defaults).isEmpty)
}

@Test func storedIDsIsEmptyWhenNothingWasEverWritten() {
    #expect(Favourites.storedIDs(in: makeDefaults()).isEmpty)
}

// MARK: - Sync merge

private func record(_ code: String, starred: Bool, at seconds: TimeInterval) -> (FlagID, FavouriteRecord) {
    let id = FlagID(collection: "countries", code: code)
    return (id, FavouriteRecord(id: id, starred: starred, changed: Date(timeIntervalSince1970: seconds)))
}

@Test func mergeKeepsFlagsStarredOnDifferentDevices() {
    let phone = Dictionary(uniqueKeysWithValues: [record("br", starred: true, at: 10)])
    let watch = Dictionary(uniqueKeysWithValues: [record("jp", starred: true, at: 20)])
    let merged = Favourites.merge(phone, watch)
    #expect(Set(merged.keys.map(\.code)) == ["br", "jp"])
}

@Test func mergeLetsTheLaterChangeWin() {
    let starredEarlier = Dictionary(uniqueKeysWithValues: [record("br", starred: true, at: 10)])
    let unstarredLater = Dictionary(uniqueKeysWithValues: [record("br", starred: false, at: 20)])

    let unstarWins = Favourites.merge(starredEarlier, unstarredLater)
    #expect(unstarWins[FlagID(collection: "countries", code: "br")]?.starred == false)

    // And the other way round: an older unstar must not undo a newer star.
    let starWins = Favourites.merge(unstarredLater, starredEarlier.mapValues {
        FavouriteRecord(id: $0.id, starred: true, changed: Date(timeIntervalSince1970: 30))
    })
    #expect(starWins[FlagID(collection: "countries", code: "br")]?.starred == true)
}

@Test func mergeIsOrderIndependent() {
    let a = Dictionary(uniqueKeysWithValues: [record("br", starred: true, at: 10)])
    let b = Dictionary(uniqueKeysWithValues: [record("br", starred: false, at: 20)])
    #expect(Favourites.merge(a, b) == Favourites.merge(b, a))
}

// MARK: - Cloud store wiring

/// Stands in for `NSUbiquitousKeyValueStore` so the syncing paths can be
/// exercised without an iCloud account.
///
/// Only the three members `Favourites` actually calls are overridden, so
/// nothing here reaches the real daemon. This is the one part of syncing a
/// simulator cannot show you: key-value storage does not travel between
/// simulators, so without a fake these paths would only ever be tried for the
/// first time on a real pair of devices.
private final class FakeCloudStore: NSUbiquitousKeyValueStore {
    private var storage: [String: Data] = [:]
    private(set) var synchronizeCount = 0

    override func data(forKey key: String) -> Data? { storage[key] }

    override func set(_ data: Data?, forKey key: String) { storage[key] = data }

    override func synchronize() -> Bool {
        synchronizeCount += 1
        return true
    }

    /// Pretend the other device wrote this, and announce it the way iCloud does.
    func receive(_ data: Data) {
        storage["favourites"] = data
        NotificationCenter.default.post(
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: self
        )
    }
}

private func payload(_ records: [(FlagID, FavouriteRecord)]) throws -> Data {
    try JSONEncoder().encode(records.map(\.1))
}

/// The pull runs in a `Task`, so the change lands a turn or two later.
@MainActor private func eventually(_ condition: () -> Bool) async -> Bool {
    for _ in 0..<200 {
        if condition() { return true }
        try? await Task.sleep(for: .milliseconds(5))
    }
    return condition()
}

@MainActor @Test func favouritesAdoptWhatTheCloudAlreadyHas() throws {
    // A fresh install on a second device: nothing local, everything in iCloud.
    let cloud = FakeCloudStore()
    cloud.set(try payload([record("br", starred: true, at: 10)]), forKey: "favourites")

    let favourites = Favourites(local: makeDefaults(), cloud: cloud)

    #expect(favourites.contains(FlagID(collection: "countries", code: "br")))
    #expect(cloud.synchronizeCount == 1)
}

@MainActor @Test func starringWritesThroughToTheCloud() throws {
    let cloud = FakeCloudStore()
    let favourites = Favourites(local: makeDefaults(), cloud: cloud)
    let jp = FlagID(collection: "countries", code: "jp")

    favourites.toggle(jp)

    let written = try #require(cloud.data(forKey: "favourites"))
    let records = try JSONDecoder().decode([FavouriteRecord].self, from: written)
    #expect(records.filter(\.starred).map(\.id) == [jp])
}

@MainActor @Test func theOtherDeviceStarringSomethingShowsUpHere() async throws {
    let cloud = FakeCloudStore()
    let favourites = Favourites(local: makeDefaults(), cloud: cloud)
    let jp = FlagID(collection: "countries", code: "jp")

    cloud.receive(try payload([record("jp", starred: true, at: 10)]))

    #expect(await eventually { favourites.contains(jp) })
}

@MainActor @Test func theOtherDeviceUnstarringSomethingRemovesItHere() async throws {
    let defaults = makeDefaults()
    let cloud = FakeCloudStore()
    let favourites = Favourites(local: defaults, cloud: cloud)
    let br = FlagID(collection: "countries", code: "br")
    favourites.toggle(br)

    // Dated ahead of the local star, which happened just now.
    cloud.receive(try payload([
        record("br", starred: false, at: Date().timeIntervalSince1970 + 60)
    ]))

    #expect(await eventually { !favourites.contains(br) })
    // The pull writes through locally too, or the next launch would resurrect it.
    #expect(!Favourites(local: defaults, cloud: nil).contains(br))
}

@MainActor @Test func aStaleCloudChangeDoesNotUndoARecentLocalOne() async throws {
    // The offline case: this device starred Brazil while iCloud still held an
    // older unstar. Overwriting rather than merging would silently lose it.
    let cloud = FakeCloudStore()
    let favourites = Favourites(local: makeDefaults(), cloud: cloud)
    let br = FlagID(collection: "countries", code: "br")
    favourites.toggle(br)

    cloud.receive(try payload([record("br", starred: false, at: 10)]))

    #expect(await eventually { !favourites.contains(br) } == false)
    #expect(favourites.contains(br))
}

// MARK: - Grouping

@Test func countriesCarryTheirContinent() throws {
    let brazil = try #require(Flag.default)
    // CLDR files countries under the continent (019 Americas) rather than the
    // subcontinent (005 South America). Five broad headings browse better than
    // twenty-two narrow ones, so the coarser grouping is the one we want.
    #expect(brazil.group == "Americas")
}

@Test func groupsAreFewEnoughToBrowse() {
    let groups = Set(Countries.flags.compactMap(\.group))
    #expect(groups.count <= 8, "\(groups.sorted())")
    #expect(groups.contains("Europe"))
}

@Test func almostEveryCountryIsGrouped() {
    let ungrouped = Countries.flags.filter { $0.group == nil }
    // A handful of regions have no continent in CLDR; a large number would
    // mean the lookup broke rather than the data being sparse.
    #expect(ungrouped.count < 10, "ungrouped: \(ungrouped.map(\.abbreviation))")
}
