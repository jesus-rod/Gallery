import Foundation
import GalleryCore

public enum LoadError: Equatable, Sendable {
    case offline
    case rateLimited
    case generic

    init(_ error: any Error) {
        switch error {
        case UnsplashAPIError.rateLimited:
            self = .rateLimited
        case let urlError as URLError where Self.offlineCodes.contains(urlError.code):
            self = .offline
        default:
            self = .generic
        }
    }

    private static let offlineCodes: Set<URLError.Code> = [
        .notConnectedToInternet,
        .networkConnectionLost,
        .dataNotAllowed,
        .timedOut,
    ]
}
