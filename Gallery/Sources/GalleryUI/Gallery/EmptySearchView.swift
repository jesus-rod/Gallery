import SwiftUI

struct EmptySearchView: View {
    let query: String

    var body: some View {
        ContentUnavailableView {
            Label(String(localized: "No photos for “\(query)”", bundle: .module), systemImage: "magnifyingglass")
        } description: {
            Text("Try a different search.", bundle: .module)
        }
        .accessibilityIdentifier("search-empty")
    }
}
