import FlagKit
import SwiftUI

@main
struct FlagsWatchApp: App {
    @State private var favourites = Favourites()

    var body: some Scene {
        WindowGroup {
            WatchFlagBrowser()
                .environment(favourites)
        }
    }
}
