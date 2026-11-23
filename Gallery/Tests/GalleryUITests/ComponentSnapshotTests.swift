#if os(iOS)
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
            "References are recorded on the developer's iOS simulator; CI runs a different iOS runtime"))
    struct ComponentSnapshotTests {
        private let device = SnapshotDevice.iPhoneSE
        private let width: CGFloat = 375

        @Test(arguments: Appearance.allCases)
        func photoCellPreviewOnly(appearance: Appearance) {
            let view = CellHost(
                photo: makePhoto(id: "1", altDescription: "Harbour at dusk 1"),
                images: snapshotImages(cached: false))

            assertSnapshot(
                of: host(view), as: screenshot(device, appearance, size: CGSize(width: 200, height: 200)),
                named: "\(appearance)")
        }

        @Test(arguments: Appearance.allCases)
        func photoCellLoaded(appearance: Appearance) {
            let view = CellHost(
                photo: makePhoto(id: "2", altDescription: "Harbour at dusk 2"),
                images: snapshotImages())

            assertSnapshot(
                of: host(view), as: screenshot(device, appearance, size: CGSize(width: 200, height: 200)),
                named: "\(appearance)")
        }

        @Test(arguments: Appearance.allCases)
        func photoCellLongCaption(appearance: Appearance) {
            let view = CellHost(
                photo: makePhoto(
                    id: "3",
                    altDescription:
                        "A long caption that keeps going well past the width of a grid cell so the truncation shows"),
                images: snapshotImages())

            assertSnapshot(
                of: host(view), as: screenshot(device, appearance, size: CGSize(width: 200, height: 200)),
                named: "\(appearance)")
        }

        @Test(arguments: Appearance.allCases)
        func offlineBanners(appearance: Appearance) {
            let view = VStack(spacing: 0) {
                OfflineBanner(reason: .offline)
                OfflineBanner(reason: .rateLimited)
            }

            assertSnapshot(
                of: host(view), as: screenshot(device, appearance, size: CGSize(width: width, height: 140)),
                named: "\(appearance)")
        }

        @Test(arguments: Appearance.allCases)
        func refreshErrorBanner(appearance: Appearance) {
            let view = RefreshErrorBanner(error: .offline, onDismiss: {})

            assertSnapshot(
                of: host(view), as: screenshot(device, appearance, size: CGSize(width: width, height: 90)),
                named: "\(appearance)")
        }

        @Test(arguments: LoadError.allSnapshotCases, Appearance.allCases)
        func loadErrorView(error: LoadError, appearance: Appearance) {
            let view = LoadErrorView(error: error, onRetry: {})

            assertSnapshot(
                of: host(view), as: screenshot(device, appearance, size: CGSize(width: width, height: 420)),
                named: "\(error)-\(appearance)")
        }

        @Test(arguments: Appearance.allCases)
        func emptySearchView(appearance: Appearance) {
            let view = EmptySearchView(query: "cats")

            assertSnapshot(
                of: host(view), as: screenshot(device, appearance, size: CGSize(width: width, height: 420)),
                named: "\(appearance)")
        }

        @Test(arguments: Appearance.allCases)
        func footerStates(appearance: Appearance) {
            let view = VStack(spacing: 0) {
                FooterView(footer: .loading, onRetry: {})
                FooterView(footer: .failed(.offline), onRetry: {})
            }

            assertSnapshot(
                of: host(view), as: screenshot(device, appearance, size: CGSize(width: width, height: 240)),
                named: "\(appearance)")
        }

        @Test(arguments: Appearance.allCases)
        func photoCreditView(appearance: Appearance) {
            let view = PhotoCreditView(photographer: makePhoto().photographer, appName: "gallery_ios")
                .padding()

            assertSnapshot(
                of: host(view), as: screenshot(device, appearance, size: CGSize(width: width, height: 80)),
                named: "\(appearance)")
        }

        @Test(arguments: Appearance.allCases)
        func fullScreenChrome(appearance: Appearance) {
            let view = ZStack {
                Image(decorative: snapshotTwoTone(for: makePhoto(id: "4"))!, scale: 1)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                FullScreenChromeLayer(
                    caption: "Harbour at dusk 4",
                    photographer: makePhoto().photographer,
                    shareURL: URL(string: "https://unsplash.com/photos/4")!,
                    appName: "gallery_ios",
                    isVisible: true,
                    isInfoPresented: .constant(false)
                )
            }

            assertSnapshot(
                of: host(view), as: screenshot(device, appearance, size: CGSize(width: width, height: 400)),
                named: "\(appearance)")
        }

        private struct CellHost: View {
            let photo: Photo
            let images: PhotoImages
            @Namespace private var namespace

            var body: some View {
                PhotoCell(
                    photo: photo,
                    images: images,
                    size: ImageSize(points: 180, scale: 2),
                    streamID: GalleryViewModel.feedStreamID,
                    zoomNamespace: namespace,
                    onOpen: { _ in }
                )
                .frame(width: 180, height: 180)
            }
        }
    }
#endif
