// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Gallery",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "GalleryCore", targets: ["GalleryCore"]),
        .library(name: "GalleryImageLoading", targets: ["GalleryImageLoading"]),
        .library(name: "GalleryUI", targets: ["GalleryUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.17.0")
    ],
    targets: [
        .target(name: "GalleryCore"),
        .testTarget(name: "GalleryCoreTests", dependencies: ["GalleryCore"]),

        .target(name: "GalleryImageLoading"),
        .testTarget(name: "GalleryImageLoadingTests", dependencies: ["GalleryImageLoading"]),

        .target(
            name: "GalleryUI",
            dependencies: ["GalleryCore"],
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "GalleryUITests",
            dependencies: [
                "GalleryUI", "GalleryCore",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ]
        ),
    ]
)
