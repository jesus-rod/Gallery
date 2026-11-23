import GalleryCore

struct PagerWindow {
    let current: Photo
    private let fullImageIDs: Set<String>

    init(pages: [Photo], currentID: String, fallback: Photo) {
        guard
            let index = pages.firstIndex(where: { $0.id == currentID })
                ?? pages.firstIndex(where: { $0.id == fallback.id })
        else {
            current = fallback
            fullImageIDs = [fallback.id]
            return
        }
        current = pages[index]
        let neighbours = pages[max(index - 1, 0)...min(index + 1, pages.count - 1)]
        fullImageIDs = Set(neighbours.map(\.id))
    }

    func isCurrent(_ id: String) -> Bool {
        id == current.id
    }

    func loadsFullImage(_ id: String) -> Bool {
        fullImageIDs.contains(id)
    }
}
