import CoreGraphics
import Foundation

public protocol ImageLoader: Sendable {
    func loadImage(from url: URL, maxPixelSize: Int) async throws -> CGImage
}
