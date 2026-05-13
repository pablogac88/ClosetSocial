import Foundation
import Testing
@testable import Domain

struct StubAuthRepository: AuthRepository {
    let session: AuthSession

    func login(email: String, password: String) async throws -> AuthSession { session }
    func register(
        username: String,
        displayName: String,
        email: String,
        password: String
    ) async throws -> AuthSession { session }
}

@Test("login normaliza email a lowercase y trimmed")
func authenticateUserUseCaseNormalizesEmail() async throws {
    let expected = AuthSession(
        token: "tok",
        user: User(id: UUID(), username: "u", displayName: "U", avatarURL: nil)
    )
    let useCase = DefaultAuthenticateUserUseCase(repository: StubAuthRepository(session: expected))
    let session = try await useCase.login(email: "  PABLO@Closet.app ", password: "x")
    #expect(session == expected)
}
