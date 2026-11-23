#if os(iOS)
    import SnapshotTesting
    import SwiftUI
    import Testing

    @testable import GalleryUI

    @MainActor
    @Suite(
        .disabled(
            if: ProcessInfo.processInfo.environment["CI"] != nil,
            "References are recorded on the developer's iOS simulator; CI runs a different iOS runtime"))
    struct DesignSystemSnapshotTests {
        private let device = SnapshotDevice.iPhoneSE
        private let width: CGFloat = 375

        @Test(arguments: Appearance.allCases)
        func scrimOverSolidColor(appearance: Appearance) {
            let view = ZStack {
                Color(uiColor: .systemOrange)
                Scrim()
            }

            assertSnapshot(
                of: host(view), as: screenshot(device, appearance, size: CGSize(width: width, height: 200)),
                named: "\(appearance)")
        }

        @Test(arguments: Appearance.allCases)
        func bannerStyle(appearance: Appearance) {
            let view = ZStack {
                LinearGradient(colors: [.teal, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                VStack(spacing: Design.Spacing.medium) {
                    Text("Short banner")
                        .bannerStyle()
                    Text("A two-line banner that wraps across the width so the multi-line layout shows")
                        .bannerStyle()
                }
            }

            assertSnapshot(
                of: host(view), as: screenshot(device, appearance, size: CGSize(width: width, height: 220)),
                named: "\(appearance)")
        }

        @Test(arguments: Appearance.allCases)
        func tokenSheet(appearance: Appearance) {
            assertSnapshot(
                of: host(TokenSheet()), as: screenshot(device, appearance, size: CGSize(width: width, height: 560)),
                named: "\(appearance)")
        }

        private struct TokenSheet: View {
            var body: some View {
                VStack(alignment: .leading, spacing: Design.Spacing.medium) {
                    Text("Spacing").font(.headline)
                    spacingBar("gridGap", Design.Spacing.gridGap)
                    spacingBar("small", Design.Spacing.small)
                    spacingBar("medium", Design.Spacing.medium)
                    Text("Hit target").font(.headline)
                    Rectangle()
                        .fill(.blue)
                        .frame(width: Design.Size.hitTarget, height: Design.Size.hitTarget)
                    Text("Opacity").font(.headline)
                    HStack(spacing: Design.Spacing.small) {
                        opacitySwatch("scrim", Design.Opacity.scrim)
                        opacitySwatch("cellScrim", Design.Opacity.cellScrim)
                        opacitySwatch("titleScrim", Design.Opacity.titleScrim)
                        opacitySwatch("secondary", Design.Opacity.secondaryText)
                    }
                }
                .padding(Design.Spacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            private func spacingBar(_ name: String, _ value: CGFloat) -> some View {
                HStack(spacing: Design.Spacing.small) {
                    Text(name).font(.caption).frame(width: 70, alignment: .leading)
                    Rectangle().fill(.blue).frame(width: value * 8, height: 12)
                }
            }

            private func opacitySwatch(_ name: String, _ opacity: Double) -> some View {
                VStack(spacing: Design.Spacing.gridGap) {
                    Rectangle()
                        .fill(.black.opacity(opacity))
                        .frame(width: 44, height: 44)
                        .overlay(Rectangle().stroke(.gray))
                    Text(name).font(.caption2)
                }
            }
        }
    }
#endif
