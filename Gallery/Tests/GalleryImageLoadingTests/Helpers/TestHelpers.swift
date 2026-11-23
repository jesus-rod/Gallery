import Foundation

let anyURL = URL(string: "https://images.example.com/any")!

func anyData() -> Data { Data("any data".utf8) }

struct AnyError: Error, Equatable {}
