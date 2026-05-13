import Foundation

struct AuthSessionDTO: Codable, Sendable {
    let token: String
    let user: UserDTO
}

struct LoginRequestDTO: Codable, Sendable {
    let email: String
    let password: String
}

struct RegisterRequestDTO: Codable, Sendable {
    let username: String
    let displayName: String
    let email: String
    let password: String
}
