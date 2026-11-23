import CoreGraphics
import Foundation

public enum BlurHash {
    public static func decode(_ hash: String, width: Int, height: Int) -> CGImage? {
        guard width > 0, height > 0, let digits = base83Digits(of: hash), digits.count >= 6 else { return nil }

        let sizeFlag = digits[0]
        let componentsX = sizeFlag % 9 + 1
        let componentsY = sizeFlag / 9 + 1
        guard digits.count == 4 + 2 * componentsX * componentsY else { return nil }

        let maximumValue = Double(digits[1] + 1) / 166
        let colors =
            [dcColor(value(of: digits[2..<6]))]
            + (1..<componentsX * componentsY).map { index in
                acColor(value(of: digits[(4 + index * 2)..<(6 + index * 2)]), maximumValue: maximumValue)
            }

        let cosinesX = cosineTable(size: width, components: componentsX)
        let cosinesY = cosineTable(size: height, components: componentsY)
        var pixels = [UInt8](repeating: 255, count: width * height * 4)

        for y in 0..<height {
            for x in 0..<width {
                var red = 0.0
                var green = 0.0
                var blue = 0.0
                for j in 0..<componentsY {
                    for i in 0..<componentsX {
                        let basis = cosinesX[x * componentsX + i] * cosinesY[y * componentsY + j]
                        let color = colors[i + j * componentsX]
                        red += color.red * basis
                        green += color.green * basis
                        blue += color.blue * basis
                    }
                }
                let offset = (y * width + x) * 4
                pixels[offset] = linearToSRGB(red)
                pixels[offset + 1] = linearToSRGB(green)
                pixels[offset + 2] = linearToSRGB(blue)
            }
        }

        return makeImage(pixels: pixels, width: width, height: height)
    }

    private struct LinearColor {
        let red: Double
        let green: Double
        let blue: Double
    }

    private static let alphabet = Array(
        "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#$%*+,-.:;=?@[]^_{|}~")
    private static let digitValues = Dictionary(uniqueKeysWithValues: alphabet.enumerated().map { ($1, $0) })

    private static func base83Digits(of hash: String) -> [Int]? {
        var digits: [Int] = []
        for character in hash {
            guard let digit = digitValues[character] else { return nil }
            digits.append(digit)
        }
        return digits
    }

    private static func value(of digits: ArraySlice<Int>) -> Int {
        digits.reduce(0) { $0 * 83 + $1 }
    }

    private static func dcColor(_ value: Int) -> LinearColor {
        LinearColor(
            red: sRGBToLinear(value >> 16),
            green: sRGBToLinear((value >> 8) & 255),
            blue: sRGBToLinear(value & 255)
        )
    }

    private static func acColor(_ value: Int, maximumValue: Double) -> LinearColor {
        func component(_ quantized: Int) -> Double {
            let normalized = Double(quantized - 9) / 9
            return copysign(normalized * normalized, normalized) * maximumValue
        }
        return LinearColor(
            red: component(value / (19 * 19)),
            green: component((value / 19) % 19),
            blue: component(value % 19)
        )
    }

    private static func cosineTable(size: Int, components: Int) -> [Double] {
        (0..<size).flatMap { position in
            (0..<components).map { component in
                cos(Double.pi * Double(position) * Double(component) / Double(size))
            }
        }
    }

    private static func sRGBToLinear(_ value: Int) -> Double {
        let normalized = Double(value) / 255
        return normalized <= 0.04045 ? normalized / 12.92 : pow((normalized + 0.055) / 1.055, 2.4)
    }

    private static func linearToSRGB(_ value: Double) -> UInt8 {
        let clamped = min(max(value, 0), 1)
        let encoded = clamped <= 0.003_130_8 ? clamped * 12.92 : 1.055 * pow(clamped, 1 / 2.4) - 0.055
        return UInt8(encoded * 255 + 0.5)
    }

    private static func makeImage(pixels: [UInt8], width: Int, height: Int) -> CGImage? {
        guard let provider = CGDataProvider(data: Data(pixels) as CFData) else { return nil }
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    }
}
