import Foundation

public protocol AuthRepository: Sendable {
    func login(email: String, password: String) async throws -> AuthSession
    func register(
        username: String,
        displayName: String,
        email: String,
        password: String
    ) async throws -> AuthSession
}
