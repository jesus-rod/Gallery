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
    targets: [
        .target(name: "GalleryCore"),
        .testTarget(name: "GalleryCoreTests", dependencies: ["GalleryCore"]),

        .target(name: "GalleryImageLoading"),
        .testTarget(name: "GalleryImageLoadingTests", dependencies: ["GalleryImageLoading"]),

        .target(
            name: "GalleryUI",
            dependencies: ["GalleryCore", "GalleryImageLoading"],
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(name: "GalleryUITests", dependencies: ["GalleryUI", "GalleryCore"]),
    ]
)
