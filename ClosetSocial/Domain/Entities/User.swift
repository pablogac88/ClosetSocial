import Foundation

public enum UserRole: String, Codable, Sendable, Equatable {
    case user
    case admin

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = UserRole(rawValue: rawValue) ?? .user
    }
}

public struct User: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let username: String
    public let displayName: String
    public let avatarURL: URL?
    public let bio: String?
    public let role: UserRole

    public init(
        id: UUID,
        username: String,
        displayName: String,
        avatarURL: URL?,
        bio: String? = nil,
        role: UserRole = .user
    ) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.bio = bio
        self.role = role
    }
}
