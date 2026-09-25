import Foundation

/// Country flags, keyed by ISO 3166-1 alpha-2.
///
/// The list and the display names both come from `Locale`, so names arrive
/// already translated into the user's language and we carry no name table.
/// The trade-off is that the exact set shifts with the OS version.
///
/// Flags are politically loaded. The position taken here is that shipping the
/// standard list is more defensible than curating it: the basis is a published
/// standard rather than our own judgement about who counts as a country.
///
/// So `excluded` is empty on purpose. The one place we restrict on political
/// grounds is where the platform already restricts, which `restrictions`
/// covers.
///
/// `uninhabited` also trims the list, but on different grounds: it drops a
/// handful of unpopulated dependencies that show a flag already in the list.
/// That is a judgement about duplicate artwork, not about who counts as a
/// country, and it is kept separate so the two never get confused.
public enum Countries: FlagCollection {
    public static let id = "countries"
    public static let displayName = "Countries"

    /// Flags withheld everywhere, regardless of device region.
    ///
    /// Empty, and that is a decision rather than an omission. Nothing in the
    /// list warrants global removal, and pulling a flag worldwide to satisfy
    /// one storefront would cost every user while making the app's neutral
    /// basis harder to defend, not easier.
    ///
    /// This exists so that a takedown request has an obvious place to land.
    /// Anything added wants a comment saying who asked and when.
    static let excluded: Set<String> = []

    /// Places with no permanent population that fly their parent's flag.
    ///
    /// Each one repeats a picture the list already shows under the country it
    /// belongs to: Bouvet Island is Norway's flag, Clipperton is France's.
    /// With nobody living there, the entry adds a duplicate and nothing else.
    ///
    /// Kept apart from `excluded` on purpose. That set is for flags withheld
    /// on request, which is a political act; this one is a rule about repeated
    /// artwork, applied only where there is no population to have a view about
    /// it. Inhabited dependencies stay even when they fly their parent's flag
    /// — Réunion, Mayotte and Svalbard among them — because someone lives
    /// there and may well want to pick the place they are from.
    ///
    /// Lowercase, like the keys in `restrictions`.
    static let uninhabited: Set<String> = [
        "bv", // Bouvet Island — Norway
        "cp", // Clipperton Island — France
        "dg", // Diego Garcia — United Kingdom
        "hm", // Heard & McDonald Islands — Australia
        "um", // U.S. Outlying Islands — United States
    ]

    public static var flags: [Flag] { cached }

    private static let cached: [Flag] = build(deviceRegion: Locale.current.region?.identifier)

    /// What the platform does with a flag in a given device region.
    enum Restriction {
        /// Not shipped at all. Matches a flag the system font will not draw.
        case withheld
        /// Drawn if already configured, but not offered in a picker.
        case unlisted
    }

    /// Where the platform restricts a flag, we restrict it the same way.
    ///
    /// This is not our own political judgement, which is the point. Apple
    /// removes the Taiwan flag from the system emoji font on devices set to
    /// China mainland, and hides it from the emoji keyboard in Hong Kong and
    /// Macau while still rendering it.
    ///
    /// While country artwork was emoji we inherited all of that for free.
    /// Bundling flag-icons SVGs took the responsibility on, so this restores
    /// it. Without it the app would show a flag in a storefront where the OS
    /// itself will not.
    static let restrictions: [String: [String: Restriction]] = [
        "CN": ["tw": .withheld],
        "HK": ["tw": .unlisted],
        "MO": ["tw": .unlisted],
    ]

    static func restriction(for code: String, deviceRegion: String?) -> Restriction? {
        guard let region = deviceRegion?.uppercased() else { return nil }
        return restrictions[region]?[code.lowercased()]
    }

    /// Takes the region rather than reading it, so the restriction wiring can
    /// be tested for regions this machine is not set to.
    static func build(deviceRegion: String?) -> [Flag] {
        let locale = Locale.current
        return Locale.Region.isoRegions
            // Continents and groupings like "European Union" carry sub-regions;
            // only leaf regions are countries or territories.
            .filter { $0.subRegions.isEmpty }
            .map(\.identifier)
            .filter { $0.count == 2 && $0.allSatisfy(\.isLetter) }
            // Lowercased on both sides: isoRegions yields "BV", while these
            // sets are keyed the way the rest of the file keys codes.
            .filter { !excluded.contains($0.lowercased()) }
            .filter { !uninhabited.contains($0.lowercased()) }
            .compactMap { code -> Flag? in
                guard let name = locale.localizedString(forRegionCode: code) else { return nil }
                let restriction = restriction(for: code, deviceRegion: deviceRegion)
                guard restriction != .withheld else { return nil }
                return Flag(
                    id: FlagID(collection: id, code: code),
                    name: name,
                    artwork: artwork(for: code),
                    abbreviation: code.uppercased(),
                    isListed: restriction != .unlisted,
                    group: continentName(of: code, in: locale)
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Real artwork where we have it, emoji otherwise.
    ///
    /// The bundled set does not cover every region `Locale` lists, and it
    /// gains flags over time, so the fallback is permanent rather than
    /// temporary scaffolding.
    static func artwork(for code: String) -> FlagArtwork {
        let code = code.lowercased()
        return CountryAssets.available.contains(code)
            ? .asset(name: "flag-\(code)")
            : .emoji(emoji(for: code))
    }

    /// The localized continent name, used as a browse heading.
    ///
    /// Continents come from the same CLDR data as the region list, so they
    /// arrive translated and stay consistent with the names beside them.
    static func continentName(of code: String, in locale: Locale) -> String? {
        guard let continent = Locale.Region(code).continent else { return nil }
        return locale.localizedString(forRegionCode: continent.identifier)
    }

    /// "BR" -> "🇧🇷". Regional indicator symbols sit at U+1F1E6, which is
    /// 127397 above "A", so each letter maps straight onto one.
    public static func emoji(for code: String) -> String {
        let scalars = code.uppercased().unicodeScalars.compactMap {
            UnicodeScalar(127397 + $0.value)
        }
        return String(String.UnicodeScalarView(scalars))
    }
}
