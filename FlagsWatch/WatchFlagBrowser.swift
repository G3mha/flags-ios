import FlagKit
import SwiftUI

struct WatchFlagBrowser: View {
    var body: some View {
        NavigationStack {
            List(FlagRegistry.shared.listedFlags) { flag in
                HStack(spacing: 10) {
                    FlagView(flag: flag, shape: .circle)
                        .frame(width: 26, height: 26)
                    Text(flag.name)
                        .font(.body)
                        .lineLimit(1)
                }
            }
            .navigationTitle("Flags")
        }
    }
}

#Preview {
    WatchFlagBrowser()
}
