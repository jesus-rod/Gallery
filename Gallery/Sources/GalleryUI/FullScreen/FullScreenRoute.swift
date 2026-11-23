import GalleryCore

struct FullScreenRoute: Hashable {
    let photo: Photo
    let gridSize: ImageSize
    let streamID: String

    var sourceID: String {
        Self.sourceID(streamID: streamID, photoID: photo.id)
    }

    static func sourceID(streamID: String, photoID: String) -> String {
        "\(streamID)-\(photoID)"
    }
}
