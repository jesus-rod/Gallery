import Foundation
import GalleryCore
import Testing

struct UnsplashRenditionTests {
    @Test func gridURL_keepsRawURLAndItsQueryItems() throws {
        let raw = URL(string: "https://images.unsplash.com/photo-1?ixid=abc&ixlib=rb-4")!

        let components = try components(of: UnsplashRendition.gridURL(raw: raw, pointWidth: 100, scale: 2, quality: 75))

        #expect(components.scheme == "https")
        #expect(components.host == "images.unsplash.com")
        #expect(components.path == "/photo-1")
        #expect(components.queryItems?.contains(URLQueryItem(name: "ixid", value: "abc")) == true)
        #expect(components.queryItems?.contains(URLQueryItem(name: "ixlib", value: "rb-4")) == true)
    }

    @Test func gridURL_addsWidthScaleQualityAndJPEGFormat() throws {
        let raw = URL(string: "https://images.unsplash.com/photo-1?ixid=abc")!

        let components = try components(
            of: UnsplashRendition.gridURL(raw: raw, pointWidth: 195.3, scale: 3, quality: 70))

        #expect(
            Set(components.queryItems ?? []) == [
                URLQueryItem(name: "ixid", value: "abc"),
                URLQueryItem(name: "w", value: "196"),
                URLQueryItem(name: "dpr", value: "3"),
                URLQueryItem(name: "q", value: "70"),
                URLQueryItem(name: "fm", value: "jpg"),
            ])
    }

    @Test func gridURL_replacesExistingSizingItemsInsteadOfDuplicating() throws {
        let raw = URL(string: "https://images.unsplash.com/photo-1?w=1080&fm=webp&q=80&dpr=1&ixid=abc")!

        let components = try components(of: UnsplashRendition.gridURL(raw: raw, pointWidth: 100, scale: 2, quality: 75))

        #expect(
            Set(components.queryItems ?? []) == [
                URLQueryItem(name: "ixid", value: "abc"),
                URLQueryItem(name: "w", value: "100"),
                URLQueryItem(name: "dpr", value: "2"),
                URLQueryItem(name: "q", value: "75"),
                URLQueryItem(name: "fm", value: "jpg"),
            ])
        #expect(components.queryItems?.count == 5)
    }

    @Test func grid_forASquarePhotoRequestsTheCellSide() throws {
        let rendition = UnsplashRendition.grid(for: photo(width: 1000, height: 1000), side: 100, scale: 2, quality: 75)

        #expect(try width(of: rendition.url) == "100")
        #expect(rendition.maxPixelSize == 200)
    }

    @Test func grid_forALandscapePhotoWidensSoTheHeightCoversTheCell() throws {
        let rendition = UnsplashRendition.grid(for: photo(width: 3000, height: 2000), side: 100, scale: 2, quality: 75)

        #expect(try width(of: rendition.url) == "150")
        #expect(rendition.maxPixelSize == 300)
    }

    @Test func grid_forAPortraitPhotoKeepsTheWidthAndDownsamplesToTheLongerHeight() throws {
        let rendition = UnsplashRendition.grid(for: photo(width: 2000, height: 3000), side: 100, scale: 2, quality: 75)

        #expect(try width(of: rendition.url) == "100")
        #expect(rendition.maxPixelSize == 300)
    }

    @Test func grid_capsExtremeAspectRatiosAtThreeToOne() throws {
        let panorama = UnsplashRendition.grid(for: photo(width: 8000, height: 1000), side: 100, scale: 2, quality: 75)
        let tower = UnsplashRendition.grid(for: photo(width: 1000, height: 8000), side: 100, scale: 2, quality: 75)

        #expect(try width(of: panorama.url) == "300")
        #expect(panorama.maxPixelSize == 600)
        #expect(try width(of: tower.url) == "100")
        #expect(tower.maxPixelSize == 600)
    }

    @Test func grid_toleratesMissingDimensions() throws {
        let rendition = UnsplashRendition.grid(for: photo(width: 0, height: 0), side: 100, scale: 2, quality: 75)

        #expect(try width(of: rendition.url) == "100")
        #expect(rendition.maxPixelSize == 200)
    }

    private func photo(width: Int, height: Int) -> Photo {
        let url = URL(string: "https://images.unsplash.com/photo-1?ixid=abc")!
        return Photo(
            id: "1", width: width, height: height, blurHash: nil, description: nil, altDescription: nil,
            renditions: Photo.Renditions(raw: url, small: url, regular: url),
            photographer: Photo.Photographer(name: "A", profileURL: url)
        )
    }

    private func width(of url: URL) throws -> String? {
        try components(of: url).queryItems?.first { $0.name == "w" }?.value
    }

    private func components(of url: URL) throws -> URLComponents {
        try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
    }
}
