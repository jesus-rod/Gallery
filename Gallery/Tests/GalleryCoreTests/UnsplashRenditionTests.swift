import Foundation
import GalleryCore
import Testing

struct UnsplashRenditionTests {
    @Test func sizedURL_keepsRawURLAndItsQueryItems() throws {
        let raw = URL(string: "https://images.unsplash.com/photo-1?ixid=abc&ixlib=rb-4")!

        let components = try components(
            of: UnsplashRendition.sizedURL(raw: raw, pointWidth: 100, scale: 2, quality: 75))

        #expect(components.scheme == "https")
        #expect(components.host == "images.unsplash.com")
        #expect(components.path == "/photo-1")
        #expect(components.queryItems?.contains(URLQueryItem(name: "ixid", value: "abc")) == true)
        #expect(components.queryItems?.contains(URLQueryItem(name: "ixlib", value: "rb-4")) == true)
    }

    @Test func sizedURL_addsWidthScaleQualityAndJPEGFormat() throws {
        let raw = URL(string: "https://images.unsplash.com/photo-1?ixid=abc")!

        let components = try components(
            of: UnsplashRendition.sizedURL(raw: raw, pointWidth: 195.3, scale: 3, quality: 70))

        #expect(
            Set(components.queryItems ?? []) == [
                URLQueryItem(name: "ixid", value: "abc"),
                URLQueryItem(name: "w", value: "196"),
                URLQueryItem(name: "dpr", value: "3"),
                URLQueryItem(name: "q", value: "70"),
                URLQueryItem(name: "fm", value: "jpg"),
            ])
    }

    @Test func sizedURL_replacesExistingSizingItemsInsteadOfDuplicating() throws {
        let raw = URL(string: "https://images.unsplash.com/photo-1?w=1080&fm=webp&q=80&dpr=1&ixid=abc")!

        let components = try components(
            of: UnsplashRendition.sizedURL(raw: raw, pointWidth: 100, scale: 2, quality: 75))

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

    @Test func grid_cropsAPortraitTallerThanTheCapToTheCap() throws {
        let rendition = UnsplashRendition.grid(for: photo(width: 1000, height: 4000), side: 100, scale: 3, quality: 75)

        #expect(try width(of: rendition.url) == "100")
        #expect(try value("h", of: rendition.url) == "300")
        #expect(try value("fit", of: rendition.url) == "crop")
        #expect(rendition.maxPixelSize == 900)
    }

    @Test func grid_doesNotCropAPortraitWithinTheCap() throws {
        let rendition = UnsplashRendition.grid(for: photo(width: 1000, height: 2000), side: 100, scale: 3, quality: 75)

        #expect(try value("h", of: rendition.url) == nil)
        #expect(try value("fit", of: rendition.url) == nil)
        #expect(rendition.maxPixelSize == 600)
    }

    @Test func grid_replacesExistingHeightAndFitItems() throws {
        let raw = "https://images.unsplash.com/photo-1?ixid=abc&h=50&fit=max"
        let rendition = UnsplashRendition.grid(
            for: photo(width: 1000, height: 4000, raw: raw), side: 100, scale: 3, quality: 75)

        let components = try components(of: rendition.url)
        #expect(components.queryItems?.filter { $0.name == "h" } == [URLQueryItem(name: "h", value: "300")])
        #expect(components.queryItems?.filter { $0.name == "fit" } == [URLQueryItem(name: "fit", value: "crop")])
    }

    @Test func grid_toleratesMissingDimensions() throws {
        let rendition = UnsplashRendition.grid(for: photo(width: 0, height: 0), side: 100, scale: 2, quality: 75)

        #expect(try width(of: rendition.url) == "100")
        #expect(rendition.maxPixelSize == 200)
    }

    @Test func fullScreen_fitsALandscapePhotoToTheContainerWidth() throws {
        let rendition = UnsplashRendition.fullScreen(
            for: photo(width: 4000, height: 3000), fitting: 400, height: 800, scale: 3, quality: 80)

        #expect(try width(of: rendition.url) == "400")
        #expect(try dpr(of: rendition.url) == "3")
        #expect(rendition.maxPixelSize == 1200)
    }

    @Test func fullScreen_fitsAPortraitPhotoToTheContainerWidthWhenItIsShortEnough() throws {
        let rendition = UnsplashRendition.fullScreen(
            for: photo(width: 3000, height: 4000), fitting: 400, height: 800, scale: 3, quality: 80)

        #expect(try width(of: rendition.url) == "400")
        #expect(rendition.maxPixelSize == 1600)
    }

    @Test func fullScreen_fitsATallPhotoToTheContainerHeight() throws {
        let rendition = UnsplashRendition.fullScreen(
            for: photo(width: 1000, height: 4000), fitting: 400, height: 800, scale: 3, quality: 80)

        #expect(try width(of: rendition.url) == "200")
        #expect(rendition.maxPixelSize == 2400)
    }

    @Test func fullScreen_fitsAPortraitPhotoInALandscapeContainer() throws {
        let rendition = UnsplashRendition.fullScreen(
            for: photo(width: 3000, height: 4000), fitting: 800, height: 400, scale: 3, quality: 80)

        #expect(try width(of: rendition.url) == "300")
        #expect(rendition.maxPixelSize == 1200)
    }

    @Test func fullScreen_treatsAPhotoWithoutDimensionsAsSquare() throws {
        let rendition = UnsplashRendition.fullScreen(
            for: photo(width: 0, height: 0), fitting: 400, height: 800, scale: 3, quality: 80)

        #expect(try width(of: rendition.url) == "400")
        #expect(rendition.maxPixelSize == 1200)
    }

    @Test func fullScreen_buildsFromTheRawRenditionWithQualityAndJPEGFormat() throws {
        let rendition = UnsplashRendition.fullScreen(
            for: photo(width: 4000, height: 3000), fitting: 400, height: 800, scale: 3, quality: 80)

        let components = try components(of: rendition.url)
        #expect(components.host == "images.unsplash.com")
        #expect(components.path == "/photo-1")
        #expect(
            Set(components.queryItems ?? []) == [
                URLQueryItem(name: "ixid", value: "abc"),
                URLQueryItem(name: "w", value: "400"),
                URLQueryItem(name: "dpr", value: "3"),
                URLQueryItem(name: "q", value: "80"),
                URLQueryItem(name: "fm", value: "jpg"),
            ])
    }

    private func dpr(of url: URL) throws -> String? {
        try components(of: url).queryItems?.first { $0.name == "dpr" }?.value
    }

    private func photo(width: Int, height: Int, raw: String = "https://images.unsplash.com/photo-1?ixid=abc") -> Photo {
        let url = URL(string: raw)!
        return Photo(
            id: "1", width: width, height: height, blurHash: nil, description: nil, altDescription: nil,
            renditions: Photo.Renditions(raw: url, small: url, regular: url),
            photographer: Photo.Photographer(name: "A", profileURL: url),
            pageURL: url
        )
    }

    private func value(_ name: String, of url: URL) throws -> String? {
        try components(of: url).queryItems?.first { $0.name == name }?.value
    }

    private func width(of url: URL) throws -> String? {
        try components(of: url).queryItems?.first { $0.name == "w" }?.value
    }

    private func components(of url: URL) throws -> URLComponents {
        try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
    }
}
