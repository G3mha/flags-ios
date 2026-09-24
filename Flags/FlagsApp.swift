import FlagKit
import SwiftUI

@main
struct FlagsApp: App {
    @State private var favourites = Favourites()

    var body: some Scene {
        WindowGroup {
            FlagBrowserView()
                .environment(favourites)
        }
    }
}
