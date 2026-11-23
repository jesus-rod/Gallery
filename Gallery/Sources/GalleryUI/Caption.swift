import Foundation
import GalleryCore

func caption(for photo: Photo) -> String {
    [photo.altDescription, photo.description]
        .compactMap { $0 }
        .first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        ?? String(localized: "Untitled photo", bundle: .module)
}
