import CoreGraphics
import Foundation
import GalleryImageLoading
import Testing

struct BlurHashTests {
    @Test func decode_deliversImageOfRequestedSize() throws {
        let image = try #require(BlurHash.decode("LEHV6nWB2yk8pyo0adR*.7kCMdnj", width: 32, height: 24))

        #expect(image.width == 32)
        #expect(image.height == 24)
    }

    @Test(arguments: ["", "00TI:", "00TI:jX", "LEHV6nWB2yk8pyo0adR*.7kCMdn", "00TI\"j"])
    func decode_deliversNilForInvalidHash(hash: String) {
        #expect(BlurHash.decode(hash, width: 32, height: 32) == nil)
    }

    @Test func decode_oneComponentHashFillsImageWithItsAverageColour() throws {
        let image = try #require(BlurHash.decode("00TI:j", width: 4, height: 4))

        for pixel in rgbaPixels(of: image) {
            #expect(pixel == [255, 0, 0, 255])
        }
    }

    @Test func decode_knownHashHasExpectedAverageColour() throws {
        let image = try #require(BlurHash.decode("LEHV6nWB2yk8pyo0adR*.7kCMdnj", width: 32, height: 32))

        let pixels = rgbaPixels(of: image)
        let average = (0..<3).map { channel in pixels.map { Int($0[channel]) }.reduce(0, +) / pixels.count }

        #expect(abs(average[0] - 0x97) <= 12)
        #expect(abs(average[1] - 0x96) <= 12)
        #expect(abs(average[2] - 0x95) <= 12)
    }
}

@Suite(.trackingLeaks)
struct PreviewCacheTests {
    @Test func preview_decodesHashAtConfiguredSize() throws {
        let sut = PreviewCache(size: 16)

        let preview = try #require(sut.preview(for: "LEHV6nWB2yk8pyo0adR*.7kCMdnj"))

        #expect(preview.width == 16)
        #expect(preview.height == 16)
    }

    @Test func preview_decodesEachHashOnce() {
        let decoder = DecoderSpy()
        let sut = PreviewCache(size: 8, decode: decoder.decode)
        trackForMemoryLeaks(decoder)

        _ = sut.preview(for: "a")
        _ = sut.preview(for: "a")
        _ = sut.preview(for: "b")

        #expect(decoder.decodedHashes == ["a", "b"])
    }
}

private final class DecoderSpy: @unchecked Sendable {
    private let lock = NSLock()
    private var _decodedHashes: [String] = []

    var decodedHashes: [String] { lock.withLock { _decodedHashes } }

    @Sendable func decode(_ hash: String, width: Int, height: Int) -> CGImage? {
        lock.withLock { _decodedHashes.append(hash) }
        return makeImage(width: width, height: height)
    }
}

private func rgbaPixels(of image: CGImage) -> [[UInt8]] {
    let width = image.width
    let height = image.height
    var bytes = [UInt8](repeating: 0, count: width * height * 4)
    bytes.withUnsafeMutableBytes { buffer in
        let context = CGContext(
            data: buffer.baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    }
    return stride(from: 0, to: bytes.count, by: 4).map { Array(bytes[$0..<$0 + 4]) }
}
