#if os(macOS)
    import AppKit
    import CoreGraphics
    import GalleryCore
    import SnapshotTesting
    import SwiftUI
    import Testing

    @testable import GalleryUI

    @MainActor
    @Suite(
        .disabled(
            if: ProcessInfo.processInfo.environment["CI"] != nil,
            "References are recorded on the developer's macOS; other macOS versions render text differently"))
    struct SnapshotTests {
        private let cellSize = CGSize(width: 180, height: 180)
        private let stateSize = CGSize(width: 390, height: 420)

        @Test(arguments: Appearance.allCases)
        func photoCell_withAPreviewOnly(appearance: Appearance) {
            let view = CellHost(images: makeImages(preview: makeSolidImage(red: 0.2, green: 0.5, blue: 0.8)))

            assertSnapshot(
                of: hosting(view, appearance, cellSize), as: .image(size: cellSize), named: appearance.rawValue)
        }

        @Test(arguments: Appearance.allCases)
        func photoCell_withALoadedImage(appearance: Appearance) {
            let view = CellHost(
                images: makeImages(
                    preview: makeSolidImage(red: 0.2, green: 0.5, blue: 0.8),
                    cached: makeSolidImage(red: 0.9, green: 0.6, blue: 0.2)))

            assertSnapshot(
                of: hosting(view, appearance, cellSize), as: .image(size: cellSize), named: appearance.rawValue)
        }

        @Test(arguments: LoadError.allSnapshotCases, Appearance.allCases)
        func loadErrorView(error: LoadError, appearance: Appearance) {
            let view = LoadErrorView(error: error, onRetry: {})

            assertSnapshot(
                of: hosting(view, appearance, stateSize), as: .image(size: stateSize),
                named: "\(error)-\(appearance.rawValue)")
        }

        @Test(arguments: Appearance.allCases)
        func emptySearchView(appearance: Appearance) {
            let view = EmptySearchView(query: "cats")

            assertSnapshot(
                of: hosting(view, appearance, stateSize), as: .image(size: stateSize), named: appearance.rawValue)
        }

        private func makeImages(preview: CGImage?, cached: CGImage? = nil) -> PhotoImages {
            PhotoImages(
                preview: { _ in preview },
                cachedImage: { _, _ in cached },
                image: { _, _ in throw CancellationError() },
                fullScreenImage: { _, _ in throw CancellationError() },
                prefetch: { _, _ in }
            )
        }

        private func hosting(_ view: some View, _ appearance: Appearance, _ size: CGSize) -> NSViewController {
            let controller = NSHostingController(
                rootView:
                    view
                    .frame(width: size.width, height: size.height)
                    .background(Color(nsColor: .windowBackgroundColor))
                    .environment(\.colorScheme, appearance.colorScheme))
            controller.view.appearance = NSAppearance(named: appearance.appearanceName)
            return controller
        }
    }

    extension LoadError {
        static let allSnapshotCases: [LoadError] = [.offline, .rateLimited, .invalidKey, .generic]
    }

    enum Appearance: String, CaseIterable, CustomTestStringConvertible {
        case light
        case dark

        var testDescription: String { rawValue }

        var colorScheme: ColorScheme { self == .light ? .light : .dark }
        var appearanceName: NSAppearance.Name { self == .light ? .aqua : .darkAqua }
    }

    private struct CellHost: View {
        let images: PhotoImages
        @Namespace private var namespace

        var body: some View {
            PhotoCell(
                photo: makePhoto(id: "1", altDescription: "A snapshot photo"),
                images: images,
                size: ImageSize(points: 180, scale: 1),
                streamID: "feed",
                zoomNamespace: namespace,
                onOpen: { _ in }
            )
            .frame(width: 180, height: 180)
        }
    }

    private func makeSolidImage(red: CGFloat, green: CGFloat, blue: CGFloat) -> CGImage {
        let context = CGContext(
            data: nil, width: 8, height: 8, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(red: red, green: green, blue: blue, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        return context.makeImage()!
    }
#endif
