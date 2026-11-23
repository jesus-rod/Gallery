#if os(iOS)
    import CoreGraphics
    import GalleryCore
    import SnapshotTesting
    import SwiftUI
    import Testing
    import UIKit

    @testable import GalleryUI

    enum Appearance: String, CaseIterable, CustomTestStringConvertible {
        case light
        case dark

        var testDescription: String { rawValue }

        var style: UIUserInterfaceStyle { self == .light ? .light : .dark }
    }

    enum SnapshotDevice: String, CaseIterable, CustomTestStringConvertible {
        case iPhoneSE
        case iPhone17
        case iPhoneDuo
        case iPad

        var testDescription: String { rawValue }

        var base: ViewImageConfig {
            switch self {
            case .iPhoneSE:
                ViewImageConfig.iPhoneSe
            case .iPhone17:
                ViewImageConfig(
                    safeArea: UIEdgeInsets(top: 62, left: 0, bottom: 34, right: 0),
                    size: CGSize(width: 402, height: 874),
                    traits: UITraitCollection(traitsFrom: [
                        UITraitCollection(horizontalSizeClass: .compact),
                        UITraitCollection(verticalSizeClass: .regular),
                        UITraitCollection(displayScale: 3),
                    ]))
            case .iPhoneDuo:
                // Unfolded inner display from the simulator's device profile (2007×2853 px at 3x).
                // Safe areas are estimates: confirm against the Duo on the user's simulator.
                ViewImageConfig(
                    safeArea: UIEdgeInsets(top: 24, left: 0, bottom: 20, right: 0),
                    size: CGSize(width: 669, height: 951),
                    traits: UITraitCollection(traitsFrom: [
                        UITraitCollection(horizontalSizeClass: .regular),
                        UITraitCollection(verticalSizeClass: .regular),
                        UITraitCollection(displayScale: 3),
                    ]))
            case .iPad:
                ViewImageConfig.iPadPro11(.portrait)
            }
        }

        func traits(_ appearance: Appearance) -> UITraitCollection {
            UITraitCollection(traitsFrom: [base.traits, UITraitCollection(userInterfaceStyle: appearance.style)])
        }

        func config(_ appearance: Appearance) -> ViewImageConfig {
            ViewImageConfig(safeArea: base.safeArea, size: base.size, traits: traits(appearance))
        }
    }

    @MainActor
    func screenshot(
        _ device: SnapshotDevice, _ appearance: Appearance, size: CGSize? = nil
    ) -> Snapshotting<UIViewController, UIImage> {
        .image(
            on: device.config(appearance), precision: 0.99, perceptualPrecision: 0.98, size: size,
            traits: device.traits(appearance))
    }

    @MainActor
    func host(_ view: some View) -> UIViewController {
        let filled =
            view
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemBackground))
        return UIHostingController(rootView: filled)
    }

    extension LoadError {
        static let allSnapshotCases: [LoadError] = [.offline, .rateLimited, .invalidKey, .generic]
    }

    func snapshotPhotos(_ range: ClosedRange<Int>) -> [Photo] {
        range.map { index in
            makePhoto(id: "\(index)", altDescription: snapshotCaption(for: index))
        }
    }

    private func snapshotCaption(for index: Int) -> String? {
        switch index {
        case 3: "A long caption that keeps going well past the width of a grid cell so the truncation shows"
        case _ where index % 5 == 0: nil
        default: "Harbour at dusk \(index)"
        }
    }

    func snapshotImages(cached: Bool = true) -> PhotoImages {
        PhotoImages(
            preview: { photo in snapshotTwoTone(for: photo) },
            cachedImage: { photo, _ in cached ? snapshotTwoTone(for: photo) : nil },
            image: { photo, _ in
                guard let image = snapshotTwoTone(for: photo) else { throw CancellationError() }
                return image
            },
            fullScreenImage: { photo, _ in
                guard let image = snapshotTwoTone(for: photo) else { throw CancellationError() }
                return image
            },
            prefetch: { _, _ in }
        )
    }

    @MainActor
    func makeSnapshotViewModel(
        feed: @escaping GalleryViewModel.LoadFeed = { Paginated(items: snapshotPhotos(1...30)) },
        offline: [Photo] = [],
        search: @escaping GalleryViewModel.Search = { _ in Paginated(items: []) }
    ) -> GalleryViewModel {
        GalleryViewModel(loadFeed: feed, loadOfflineFeed: { offline }, search: search)
    }

    private let snapshotPalette: [(red: CGFloat, green: CGFloat, blue: CGFloat)] = [
        (0.85, 0.45, 0.25), (0.25, 0.55, 0.80), (0.35, 0.70, 0.45),
        (0.90, 0.75, 0.30), (0.55, 0.35, 0.75), (0.20, 0.25, 0.35),
    ]

    func snapshotTwoTone(for photo: Photo) -> CGImage? {
        let index = (Int(photo.id) ?? 0) % 6
        let top = snapshotPalette[index]
        let bottom = snapshotPalette[(index + 3) % 6]
        let context = CGContext(
            data: nil, width: 16, height: 16, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        context?.setFillColor(CGColor(srgbRed: top.red, green: top.green, blue: top.blue, alpha: 1))
        context?.fill(CGRect(x: 0, y: 8, width: 16, height: 8))
        context?.setFillColor(CGColor(srgbRed: bottom.red, green: bottom.green, blue: bottom.blue, alpha: 1))
        context?.fill(CGRect(x: 0, y: 0, width: 16, height: 8))
        return context?.makeImage()
    }
#endif
