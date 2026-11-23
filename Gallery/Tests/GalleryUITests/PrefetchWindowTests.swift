import GalleryCore
import Testing

@testable import GalleryUI

struct PrefetchWindowTests {
    private let photos = makePhotos(1...10)

    @Test func window_isTheNextPhotosAfterTheAppearingOne() {
        let window = prefetchWindow(after: photos[2], in: photos, distance: 3)

        #expect(window.map(\.id) == ["4", "5", "6"])
    }

    @Test func window_stopsAtTheEnd() {
        let window = prefetchWindow(after: photos[8], in: photos, distance: 3)

        #expect(window.map(\.id) == ["10"])
    }

    @Test func window_isEmptyForTheLastPhotoOrAnUnknownOne() {
        #expect(prefetchWindow(after: photos[9], in: photos, distance: 3).isEmpty)
        #expect(prefetchWindow(after: makePhoto(id: "unknown"), in: photos, distance: 3).isEmpty)
    }
}
