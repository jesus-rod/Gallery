#if os(iOS)
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
    struct ScreenSnapshotTests {
        @Test(arguments: SnapshotDevice.allCases, Appearance.allCases)
        func feedLoaded(device: SnapshotDevice, appearance: Appearance) async {
            let viewModel = makeSnapshotViewModel()
            await viewModel.load()

            assertSnapshot(
                of: host(root(viewModel)), as: .wait(for: 0.3, on: screenshot(device, appearance)),
                named: "\(device)-\(appearance)")
        }

        @Test(arguments: SnapshotDevice.allCases, Appearance.allCases)
        func feedLoading(device: SnapshotDevice, appearance: Appearance) async {
            let viewModel = makeSnapshotViewModel(feed: {
                try await Task.sleep(for: .seconds(3600))
                return Paginated(items: [])
            })

            assertSnapshot(
                of: host(root(viewModel)), as: .wait(for: 0.3, on: screenshot(device, appearance)),
                named: "\(device)-\(appearance)")
        }

        @Test(arguments: SnapshotDevice.allCases, Appearance.allCases)
        func feedFirstPageError(device: SnapshotDevice, appearance: Appearance) async {
            let viewModel = makeSnapshotViewModel(feed: { throw URLError(.notConnectedToInternet) })
            await viewModel.load()

            assertSnapshot(
                of: host(root(viewModel)), as: .wait(for: 0.3, on: screenshot(device, appearance)),
                named: "\(device)-\(appearance)")
        }

        @Test(arguments: SnapshotDevice.allCases, Appearance.allCases)
        func offlineFeed(device: SnapshotDevice, appearance: Appearance) async {
            let viewModel = makeSnapshotViewModel(
                feed: { throw URLError(.notConnectedToInternet) },
                offline: snapshotPhotos(1...12))
            await viewModel.load()

            assertSnapshot(
                of: host(root(viewModel)), as: .wait(for: 0.3, on: screenshot(device, appearance)),
                named: "\(device)-\(appearance)")
        }

        @Test(arguments: SnapshotDevice.allCases, Appearance.allCases)
        func searchResults(device: SnapshotDevice, appearance: Appearance) async {
            let viewModel = makeSnapshotViewModel(search: { _ in Paginated(items: snapshotPhotos(31...60)) })
            await viewModel.load()
            await viewModel.search("cats")

            assertSnapshot(
                of: host(root(viewModel)), as: .wait(for: 0.3, on: screenshot(device, appearance)),
                named: "\(device)-\(appearance)")
        }

        @Test(arguments: SnapshotDevice.allCases, Appearance.allCases)
        func emptySearch(device: SnapshotDevice, appearance: Appearance) async {
            let viewModel = makeSnapshotViewModel(search: { _ in Paginated(items: []) })
            await viewModel.load()
            await viewModel.search("cats")

            assertSnapshot(
                of: host(root(viewModel)), as: .wait(for: 0.3, on: screenshot(device, appearance)),
                named: "\(device)-\(appearance)")
        }

        @Test(arguments: SnapshotDevice.allCases, Appearance.allCases)
        func fullScreen(device: SnapshotDevice, appearance: Appearance) {
            let photos = snapshotPhotos(1...12)
            let route = FullScreenRoute(
                photo: photos[6], gridSize: ImageSize(points: 180, scale: 2), streamID: GalleryViewModel.feedStreamID)
            let view = FullScreenPhotoView(
                route: route,
                photos: photos,
                images: snapshotImages(),
                referralAppName: "gallery_ios",
                currentID: .constant(route.photo.id)
            )

            assertSnapshot(
                of: host(view), as: .wait(for: 0.3, on: screenshot(device, appearance)),
                named: "\(device)-\(appearance)")
        }

        private func root(_ viewModel: GalleryViewModel) -> some View {
            GalleryRootView(viewModel: viewModel, images: snapshotImages(), referralAppName: "gallery_ios")
        }
    }
#endif
