import GalleryCore

public enum LoadError: Equatable, Sendable {
    case offline
    case rateLimited
    case invalidKey
    case generic

    init(_ error: any Error) {
        switch LoadFailure(error) {
        case .offline:
            self = .offline
        case .rateLimited:
            self = .rateLimited
        case .unauthorized:
            self = .invalidKey
        case .other:
            self = .generic
        }
    }
}
