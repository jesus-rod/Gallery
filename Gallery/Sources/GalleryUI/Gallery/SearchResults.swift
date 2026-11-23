public struct SearchResults: Equatable, Sendable {
    public let query: String
    public let state: StreamState

    public init(query: String, state: StreamState) {
        self.query = query
        self.state = state
    }
}
