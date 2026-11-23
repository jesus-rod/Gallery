import Foundation

extension HTTPURLResponse {
    var hasExhaustedRequestBudget: Bool {
        statusCode == 403 && value(forHTTPHeaderField: "X-Ratelimit-Remaining") == "0"
    }

    func requireDecodable<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        if hasExhaustedRequestBudget {
            throw UnsplashAPIError.rateLimited
        }
        if statusCode == 401 {
            throw UnsplashAPIError.unauthorized
        }
        guard statusCode == 200, let value = try? JSONDecoder.unsplash.decode(type, from: data) else {
            throw UnsplashAPIError.invalidData
        }
        return value
    }
}
