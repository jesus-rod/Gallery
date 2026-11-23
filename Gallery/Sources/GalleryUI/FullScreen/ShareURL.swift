import Foundation
import GalleryCore

func shareURL(for photo: Photo, appName: String) -> URL {
    UnsplashAttribution.referralURL(photo.pageURL, appName: appName)
}
