import GalleryCore
import Testing

@testable import GalleryUI

struct PagerWindowTests {
    private let photos = makePhotos(1...10)

    @Test func current_isThePhotoWithTheCurrentID() {
        let window = PagerWindow(pages: photos, currentID: "4", fallback: photos[0])

        #expect(window.current.id == "4")
        #expect(window.isCurrent("4"))
        #expect(!window.isCurrent("5"))
    }

    @Test func current_fallsBackToTheRoutePhotoWhenTheIDIsNotInTheStream() {
        let window = PagerWindow(pages: photos, currentID: "unknown", fallback: photos[6])

        #expect(window.current.id == "7")
    }

    @Test func loadsFullImage_forTheCurrentPageAndItsNeighboursOnly() {
        let window = PagerWindow(pages: photos, currentID: "4", fallback: photos[0])

        let loading = photos.map(\.id).filter(window.loadsFullImage)

        #expect(loading == ["3", "4", "5"])
    }

    @Test func loadsFullImage_stopsAtTheEdgesOfTheStream() {
        let first = PagerWindow(pages: photos, currentID: "1", fallback: photos[0])
        let last = PagerWindow(pages: photos, currentID: "10", fallback: photos[0])

        #expect(photos.map(\.id).filter(first.loadsFullImage) == ["1", "2"])
        #expect(photos.map(\.id).filter(last.loadsFullImage) == ["9", "10"])
    }
}
