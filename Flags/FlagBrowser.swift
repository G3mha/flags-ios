import FlagKit
import SwiftUI

/// Browse what is available and confirm it renders. Adding a flag to a widget
/// or complication happens in the system's own widget editor, not here.
struct FlagBrowser: View {
    @State private var query = ""

    private var results: [Flag] {
        FlagRegistry.shared.search(query, limit: .max)
    }

    var body: some View {
        NavigationStack {
            List(results) { flag in
                HStack(spacing: 12) {
                    FlagView(flag: flag, shape: .circle)
                        .frame(width: 32, height: 32)
                    Text(flag.name)
                }
            }
            .listStyle(.plain)
            .searchable(text: $query, prompt: "Search flags")
            .navigationTitle("Flags")
            .overlay {
                if results.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
            }
        }
    }
}

#Preview {
    FlagBrowser()
}
