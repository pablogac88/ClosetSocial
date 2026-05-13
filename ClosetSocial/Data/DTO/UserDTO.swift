import Foundation

struct UserDTO: Codable, Sendable, Equatable, Identifiable {
    let id: UUID
    let username: String
    let displayName: String
    let avatarURL: String?
}
