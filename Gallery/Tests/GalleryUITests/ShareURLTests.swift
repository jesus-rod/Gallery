import Foundation
import GalleryCore
import Testing

@testable import GalleryUI

struct ShareURLTests {
    @Test func sharesThePhotosUnsplashPageWithReferralParameters() {
        let photo = makePhoto(id: "abc")

        #expect(
            shareURL(for: photo, appName: "gallery_ios")
                == URL(string: "https://unsplash.com/photos/abc?utm_source=gallery_ios&utm_medium=referral")!)
    }
}
