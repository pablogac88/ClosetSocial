import Foundation

/// Único punto de entrada para login/registro desde features.
/// Encapsula la normalización de email y la elección login vs register.
public protocol AuthenticateUserUseCase: Sendable {
    func login(email: String, password: String) async throws -> AuthSession
    func register(
        username: String,
        displayName: String,
        email: String,
        password: String
    ) async throws -> AuthSession
}

public struct DefaultAuthenticateUserUseCase: AuthenticateUserUseCase {
    private let repository: any AuthRepository

    public init(repository: any AuthRepository) {
        self.repository = repository
    }

    public func login(email: String, password: String) async throws -> AuthSession {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return try await repository.login(email: normalizedEmail, password: password)
    }

    public func register(
        username: String,
        displayName: String,
        email: String,
        password: String
    ) async throws -> AuthSession {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDisplay = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return try await repository.register(
            username: trimmedUsername,
            displayName: trimmedDisplay,
            email: normalizedEmail,
            password: password
        )
    }
}
