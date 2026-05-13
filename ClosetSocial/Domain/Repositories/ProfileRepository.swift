import Foundation

public protocol ProfileRepository: Sendable {
    func fetchProfile(token: String) async throws -> UserProfile
}
