import Foundation

public enum UnsplashRendition {
    public struct Sized: Equatable, Sendable {
        public let url: URL
        public let maxPixelSize: Int
    }

    public static func grid(for photo: Photo, side: Double, scale: Double, quality: Int) -> Sized {
        let aspectRatio = photo.width > 0 && photo.height > 0 ? Double(photo.width) / Double(photo.height) : 1
        let widthFactor = min(max(aspectRatio, 1), maximumAspectRatio)
        let longestSideFactor = min(max(aspectRatio, 1 / aspectRatio), maximumAspectRatio)
        return Sized(
            url: sizedURL(raw: photo.renditions.raw, pointWidth: side * widthFactor, scale: scale, quality: quality),
            maxPixelSize: Int((side * scale * longestSideFactor).rounded(.up))
        )
    }

    public static func fullScreen(for photo: Photo, fitting width: Double, height: Double, scale: Double, quality: Int)
        -> Sized
    {
        let aspectRatio = photo.width > 0 && photo.height > 0 ? Double(photo.width) / Double(photo.height) : 1
        let fittedWidth = min(width, height * aspectRatio)
        let fittedHeight = fittedWidth / aspectRatio
        return Sized(
            url: sizedURL(raw: photo.renditions.raw, pointWidth: fittedWidth, scale: scale, quality: quality),
            maxPixelSize: Int((max(fittedWidth, fittedHeight) * scale).rounded(.up))
        )
    }

    private static let maximumAspectRatio = 3.0
    public static func sizedURL(raw: URL, pointWidth: Double, scale: Double, quality: Int) -> URL {
        guard var components = URLComponents(url: raw, resolvingAgainstBaseURL: false) else { return raw }
        let sizing = [
            URLQueryItem(name: "w", value: String(Int(pointWidth.rounded(.up)))),
            URLQueryItem(name: "dpr", value: format(scale)),
            URLQueryItem(name: "q", value: String(quality)),
            URLQueryItem(name: "fm", value: "jpg"),
        ]
        let sizingNames = Set(sizing.map(\.name))
        let kept = (components.queryItems ?? []).filter { !sizingNames.contains($0.name) }
        components.queryItems = kept + sizing
        return components.url ?? raw
    }

    private static func format(_ scale: Double) -> String {
        scale == scale.rounded() ? String(Int(scale)) : String(scale)
    }
}
