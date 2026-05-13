import Foundation

struct UserDTO: Codable, Sendable {
    let id: UUID
    let username: String
    let displayName: String
    let avatarURL: String?
}
