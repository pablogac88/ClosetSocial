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

    public func fetchFollowers(userID: UUID, token: String) async throws -> [User] {
        let dtos = try await sender.send(
            path: ClosetSocialEndpoint.userFollowers(id: userID),
            method: .get,
            token: token,
            as: [UserDTO].self
        )
        return dtos.map { $0.toDomain() }
    }

    public func fetchFollowing(userID: UUID, token: String) async throws -> [User] {
        let dtos = try await sender.send(
            path: ClosetSocialEndpoint.userFollowing(id: userID),
            method: .get,
            token: token,
            as: [UserDTO].self
        )
        return dtos.map { $0.toDomain() }
    }

    public func updateProfile(
        displayName: String,
        bio: String?,
        avatarURL: String?,
        token: String
    ) async throws -> UserProfile {
        let dto = try await sender.send(
            path: ClosetSocialEndpoint.profile,
            method: .patch,
            body: UpdateProfileRequestDTO(displayName: displayName, bio: bio, avatarURL: avatarURL),
            token: token,
            as: UserProfileDTO.self
        )
        return dto.toDomain()
    }

    public func follow(userID: UUID, token: String) async throws {
        try await sender.sendVoid(
            path: ClosetSocialEndpoint.followUser(id: userID),
            method: .post,
            token: token
        )
    }

    public func unfollow(userID: UUID, token: String) async throws {
        try await sender.sendVoid(
            path: ClosetSocialEndpoint.followUser(id: userID),
            method: .delete,
            token: token
        )
    }
}
