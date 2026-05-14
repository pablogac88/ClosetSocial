import Foundation

public protocol ProfileRepository: Sendable {
    func fetchProfile(token: String) async throws -> UserProfile
    func fetchPublicProfile(userID: UUID, token: String) async throws -> PublicUserProfile
    func fetchFollowers(userID: UUID, token: String) async throws -> [User]
    func fetchFollowing(userID: UUID, token: String) async throws -> [User]
    func follow(userID: UUID, token: String) async throws
    func unfollow(userID: UUID, token: String) async throws
    func updateProfile(
        displayName: String,
        bio: String?,
        avatarURL: String?,
        token: String
    ) async throws -> UserProfile
}
