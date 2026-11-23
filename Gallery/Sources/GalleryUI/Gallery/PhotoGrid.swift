import GalleryCore
import SwiftUI

struct PhotoGrid: View {
    let photos: [Photo]
    let footer: StreamState.Footer
    let onPhotoAppear: (Photo) -> Void
    let onRetry: () -> Void

    var body: some View {
        ScrollView {
            SquareGrid {
                ForEach(photos, id: \.id) { photo in
                    PhotoCell(photo: photo)
                        .onAppear { onPhotoAppear(photo) }
                }
            }
            FooterView(footer: footer, onRetry: onRetry)
        }
        .accessibilityIdentifier("photo-grid")
    }
}

struct SquareGrid<Content: View>: View {
    @ViewBuilder let content: Content

    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        private var columnCount: Int { horizontalSizeClass == .regular ? 3 : 2 }
    #else
        private let columnCount = 3
    #endif

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: columnCount),
            spacing: gridSpacing
        ) {
            content
        }
    }
}

private let gridSpacing: CGFloat = 2

struct PhotoCell: View {
    let photo: Photo

    var body: some View {
        Rectangle()
            .fill(.quaternary)
            .aspectRatio(1, contentMode: .fit)
            .accessibilityElement()
            .accessibilityLabel(caption(for: photo))
            .accessibilityAddTraits(.isImage)
            .accessibilityIdentifier("photo-cell")
    }
}

struct FooterView: View {
    let footer: StreamState.Footer
    let onRetry: () -> Void

    var body: some View {
        switch footer {
        case .idle, .end:
            EmptyView()
        case .loading:
            ProgressView()
                .padding()
                .accessibilityIdentifier("footer-loading")
        case .failed(let error):
            VStack(spacing: 8) {
                Text(error.title)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button(action: onRetry) {
                    Text("Retry", bundle: .module)
                }
                .accessibilityIdentifier("footer-retry")
            }
            .padding()
        }
    }
}
