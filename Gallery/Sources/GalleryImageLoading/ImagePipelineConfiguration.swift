public struct ImagePipelineConfiguration: Sendable {
    public var memoryCostLimit: Int
    public var diskByteLimit: Int
    public var prefetchDistance: Int
    public var previewSize: Int
    public var renditionQuality: Int

    public init(
        memoryCostLimit: Int, diskByteLimit: Int, prefetchDistance: Int, previewSize: Int, renditionQuality: Int
    ) {
        self.memoryCostLimit = memoryCostLimit
        self.diskByteLimit = diskByteLimit
        self.prefetchDistance = prefetchDistance
        self.previewSize = previewSize
        self.renditionQuality = renditionQuality
    }

    public static let `default` = ImagePipelineConfiguration(
        memoryCostLimit: 100 * 1024 * 1024,
        diskByteLimit: 200 * 1024 * 1024,
        prefetchDistance: 9,
        previewSize: 32,
        renditionQuality: 75
    )
}
