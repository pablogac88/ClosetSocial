import Foundation

struct AuthSessionDTO: Codable, Sendable, Equatable {
    let token: String
    let user: UserDTO
}

struct LoginRequestDTO: Codable, Sendable, Equatable {
    let email: String
    let password: String
}

struct RegisterRequestDTO: Codable, Sendable, Equatable {
    let username: String
    let displayName: String
    let email: String
    let password: String
}
