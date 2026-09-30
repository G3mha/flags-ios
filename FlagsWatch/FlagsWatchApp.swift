import AppIntents
import FlagKit
import SwiftUI

@main
struct FlagsWatchApp: App {
    // Shares favourites across devices once Favourites.cloudStore returns
    // the iCloud store; device-local until then.
    @State private var favourites = Favourites(cloud: Favourites.cloudStore)

    var body: some Scene {
        WindowGroup {
            WatchFlagBrowser()
                .environment(favourites)
        }
    }
}

/// Pulls FlagKit's intent metadata into the watch app. See FlagKitAppIntents.
///
/// The extensions each declare this for themselves, and that is enough on iOS.
/// It is not enough on watchOS: a complication previews correctly in the picker,
/// because that renders a recommendation the extension built in memory, and then
/// shows the redacted placeholder forever once it is placed, because the stored
/// configuration is decoded against the *app's* metadata and `SelectFlagIntent`
/// was not in it.
///
/// The symptom is a complication that looks like it has no timeline, which sends
/// you hunting through the artwork. It is worth knowing that the picker working
/// tells you nothing about whether the configured complication will.
struct FlagsWatchAppIntents: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] {
        [FlagKitAppIntents.self]
    }
}
