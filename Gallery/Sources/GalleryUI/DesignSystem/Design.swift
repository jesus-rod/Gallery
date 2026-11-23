import SwiftUI

enum Design {
    enum Spacing {
        static let gridGap: CGFloat = 2
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
    }

    enum Size {
        static let hitTarget: CGFloat = 44
        static let bannerCornerRadius: CGFloat = 20
    }

    enum Opacity {
        static let scrim = 0.6
        static let cellScrim = 0.45
        static let titleScrim = 0.45
        static let secondaryText = 0.75
    }

    enum Ambient {
        static let blurRadius: CGFloat = 60
        static let dim = 0.3
    }

    enum Hero {
        static let regularWidthMaximumHeight: CGFloat = 480
        static let regularWidth: CGFloat = 600

        static func height(for container: CGSize) -> CGFloat {
            let isLandscape = container.width > container.height
            let share = container.height * (isLandscape ? 0.5 : 0.6)
            let capped = container.width >= regularWidth ? min(share, regularWidthMaximumHeight) : share
            return capped.rounded()
        }
    }

    enum Motion {
        static func imageFade(reduceMotion: Bool) -> Animation? {
            reduceMotion ? nil : .easeOut(duration: 0.25)
        }

        static func chromeToggle(reduceMotion: Bool) -> Animation? {
            reduceMotion ? nil : .easeInOut(duration: 0.3)
        }

        static let parallaxFactor: CGFloat = 0.3

        static func pageCrossFade(reduceMotion: Bool) -> Animation? {
            reduceMotion ? nil : .easeInOut(duration: 0.35)
        }

        static func streamSwitch(reduceMotion: Bool) -> Animation? {
            reduceMotion ? nil : .easeInOut(duration: 0.2)
        }

        static func banner(reduceMotion: Bool) -> Animation? {
            reduceMotion ? nil : .easeInOut(duration: 0.25)
        }
    }
}
