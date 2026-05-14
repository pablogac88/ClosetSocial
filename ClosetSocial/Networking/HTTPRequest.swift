import Foundation

public struct HTTPRequestQueryItem: Sendable, Equatable {
    public let name: String
    public let value: String?

    public init(name: String, value: String?) {
        self.name = name
        self.value = value
    }
}

public struct HTTPRequest: Sendable {
    public let method: HTTPMethod
    public let path: String
    public let queryItems: [HTTPRequestQueryItem]
    public let body: Data?
    public let bearerToken: String?
    public let extraHeaders: [String: String]

    public init(
        method: HTTPMethod,
        path: String,
        queryItems: [HTTPRequestQueryItem] = [],
        body: Data? = nil,
        bearerToken: String? = nil,
        extraHeaders: [String: String] = [:]
    ) {
        self.method = method
        self.path = path
        self.queryItems = queryItems
        self.body = body
        self.bearerToken = bearerToken
        self.extraHeaders = extraHeaders
    }
}
