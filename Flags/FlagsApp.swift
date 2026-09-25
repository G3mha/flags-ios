import FlagKit
import SwiftUI

@main
struct FlagsApp: App {
    // Shares favourites across devices once Favourites.cloudStore returns
    // the iCloud store; device-local until then.
    @State private var favourites = Favourites(cloud: Favourites.cloudStore)

    var body: some Scene {
        WindowGroup {
            FlagBrowserView()
                .environment(favourites)
        }
    }
}
