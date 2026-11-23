import Foundation

public enum LoadFailure: Equatable, Sendable {
    case offline
    case rateLimited
    case unauthorized
    case other

    public init(_ error: any Error) {
        switch error {
        case UnsplashAPIError.rateLimited:
            self = .rateLimited
        case UnsplashAPIError.unauthorized:
            self = .unauthorized
        case let urlError as URLError where Self.offlineCodes.contains(urlError.code):
            self = .offline
        default:
            self = .other
        }
    }

    private static let offlineCodes: Set<URLError.Code> = [
        .notConnectedToInternet,
        .networkConnectionLost,
        .dataNotAllowed,
        .timedOut,
    ]
}
