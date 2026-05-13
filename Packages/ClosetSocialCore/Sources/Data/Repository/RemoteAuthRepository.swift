import Foundation
import Domain
import Networking

public struct RemoteAuthRepository: AuthRepository {
    private let sender: RemoteRequestSender

    public init(client: any HTTPClient, encoder: JSONEncoder, decoder: JSONDecoder) {
        self.sender = RemoteRequestSender(client: client, encoder: encoder, decoder: decoder)
    }

    public func login(email: String, password: String) async throws -> AuthSession {
        let dto = try await sender.send(
            path: ClosetSocialEndpoint.login,
            method: .post,
            body: LoginRequestDTO(email: email, password: password),
            as: AuthSessionDTO.self
        )
        return dto.toDomain()
    }

    public func register(
        username: String,
        displayName: String,
        email: String,
        password: String
    ) async throws -> AuthSession {
        let dto = try await sender.send(
            path: ClosetSocialEndpoint.register,
            method: .post,
            body: RegisterRequestDTO(
                username: username,
                displayName: displayName,
                email: email,
                password: password
            ),
            as: AuthSessionDTO.self
        )
        return dto.toDomain()
    }
}
