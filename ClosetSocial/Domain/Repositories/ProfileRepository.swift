import Foundation

public protocol ProfileRepository: Sendable {
    func fetchProfile(token: String) async throws -> UserProfile
    func fetchPublicProfile(userID: UUID, token: String) async throws -> PublicUserProfile
    func follow(userID: UUID, token: String) async throws
    func unfollow(userID: UUID, token: String) async throws
}
