import Foundation

extension HTTPURLResponse {
    var hasExhaustedRequestBudget: Bool {
        statusCode == 403 && value(forHTTPHeaderField: "X-Ratelimit-Remaining") == "0"
    }
}
