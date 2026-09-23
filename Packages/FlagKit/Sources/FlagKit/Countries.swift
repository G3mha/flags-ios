import Foundation

/// Country flags, keyed by ISO 3166-1 alpha-2.
///
/// The list and the display names both come from `Locale`, so names arrive
/// already translated into the user's language and we carry no name table.
/// The trade-off is that the exact set shifts with the OS version.
///
/// Flags are politically loaded and Apple has pulled apps over specific ones,
/// so `excluded` exists as the place to make those calls explicitly rather
/// than inheriting whatever the system happens to list. Audit it before
/// shipping.
public enum Countries: FlagCollection {
    public static let id = "countries"
    public static let displayName = "Countries"

    /// Regions the system lists that we deliberately do not ship.
    /// Empty for now; every entry added here wants a comment saying why.
    static let excluded: Set<String> = []

    public static var flags: [Flag] { cached }

    private static let cached: [Flag] = build()

    private static func build() -> [Flag] {
        let locale = Locale.current
        return Locale.Region.isoRegions
            // Continents and groupings like "European Union" carry sub-regions;
            // only leaf regions are countries or territories.
            .filter { $0.subRegions.isEmpty }
            .map(\.identifier)
            .filter { $0.count == 2 && $0.allSatisfy(\.isLetter) }
            .filter { !excluded.contains($0) }
            .compactMap { code -> Flag? in
                guard let name = locale.localizedString(forRegionCode: code) else { return nil }
                return Flag(
                    id: FlagID(collection: id, code: code),
                    name: name,
                    artwork: artwork(for: code),
                    abbreviation: code.uppercased()
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

    /// "BR" -> "🇧🇷". Regional indicator symbols sit at U+1F1E6, which is
    /// 127397 above "A", so each letter maps straight onto one.
    public static func emoji(for code: String) -> String {
        let scalars = code.uppercased().unicodeScalars.compactMap {
            UnicodeScalar(127397 + $0.value)
        }
        return String(String.UnicodeScalarView(scalars))
    }
}
