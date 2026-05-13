import Foundation

public struct User: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let username: String
    public let displayName: String
    public let avatarURL: URL?
    public let bio: String?

    public init(
        id: UUID,
        username: String,
        displayName: String,
        avatarURL: URL?,
        bio: String? = nil
    ) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.bio = bio
    }
}
