import Foundation

public struct AuthSession: Codable, Sendable, Equatable {
    public let token: String
    public let user: User

    public init(token: String, user: User) {
        self.token = token
        self.user = user
    }
}
