import SwiftUI

extension LoadError {
    var title: String {
        switch self {
        case .offline: String(localized: "You're offline", bundle: .module)
        case .rateLimited: String(localized: "Taking a short break", bundle: .module)
        case .invalidKey: String(localized: "Access key not accepted", bundle: .module)
        case .generic: String(localized: "Something went wrong", bundle: .module)
        }
    }

    var message: String {
        switch self {
        case .offline:
            String(localized: "Check your connection and try again.", bundle: .module)
        case .rateLimited:
            String(
                localized: "We've reached the hourly limit for new photos. Try again in a few minutes.",
                bundle: .module
            )
        case .invalidKey:
            String(
                localized: "Check the Unsplash access key in Config/Secrets.xcconfig, then try again.",
                bundle: .module
            )
        case .generic:
            String(localized: "We couldn't load photos. Please try again.", bundle: .module)
        }
    }

    var systemImage: String {
        switch self {
        case .offline: "wifi.slash"
        case .rateLimited: "hourglass"
        case .invalidKey: "key"
        case .generic: "exclamationmark.triangle"
        }
    }
}
