import GalleryCore

public enum StreamState: Equatable, Sendable {
    case loading
    case failed(LoadError)
    case loaded(photos: [Photo], footer: Footer)

    public enum Footer: Equatable, Sendable {
        case idle
        case end
    }
}
