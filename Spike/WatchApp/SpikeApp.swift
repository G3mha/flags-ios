import SwiftUI
import WidgetKit

@main
struct SpikeApp: App {
    var body: some Scene {
        WindowGroup {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Flag spike").font(.headline)
                    Text("Long-press the watch face, tap Edit, swipe to Complications and add the four spike widgets.")
                        .font(.caption2)
                }
                .padding()
            }
            .onAppear { WidgetCenter.shared.reloadAllTimelines() }
        }
    }
}
