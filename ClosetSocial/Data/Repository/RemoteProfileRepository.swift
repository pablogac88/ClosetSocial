import Foundation

public struct RemoteProfileRepository: ProfileRepository {
    private let sender: RemoteRequestSender

    public init(client: any HTTPClient, encoder: JSONEncoder, decoder: JSONDecoder) {
        self.sender = RemoteRequestSender(client: client, encoder: encoder, decoder: decoder)
    }

    public func fetchProfile(token: String) async throws -> UserProfile {
        let dto = try await sender.send(
            path: ClosetSocialEndpoint.profile,
            method: .get,
            token: token,
            as: UserProfileDTO.self
        )
        return dto.toDomain()
    }

    public func fetchPublicProfile(userID: UUID, token: String) async throws -> PublicUserProfile {
        let dto = try await sender.send(
            path: ClosetSocialEndpoint.userProfile(id: userID),
            method: .get,
            token: token,
            as: PublicUserProfileDTO.self
        )
        return dto.toDomain()
    }
}
