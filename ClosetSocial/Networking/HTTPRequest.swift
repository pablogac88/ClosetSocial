import Foundation

public struct HTTPRequest: Sendable {
    public let method: HTTPMethod
    public let path: String
    public let body: Data?
    public let bearerToken: String?
    public let extraHeaders: [String: String]

    public init(
        method: HTTPMethod,
        path: String,
        body: Data? = nil,
        bearerToken: String? = nil,
        extraHeaders: [String: String] = [:]
    ) {
        self.method = method
        self.path = path
        self.body = body
        self.bearerToken = bearerToken
        self.extraHeaders = extraHeaders
    }
}
