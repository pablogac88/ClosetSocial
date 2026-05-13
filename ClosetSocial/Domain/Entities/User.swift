import Foundation

public struct User: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let username: String
    public let displayName: String
    public let avatarURL: URL?

    public init(
        id: UUID,
        username: String,
        displayName: String,
        avatarURL: URL?
    ) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.avatarURL = avatarURL
    }
}
