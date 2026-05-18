import Foundation

public struct RemoteTimelineRepository: TimelineRepository {
    private let sender: RemoteRequestSender

    public init(client: any HTTPClient, encoder: JSONEncoder, decoder: JSONDecoder) {
        self.sender = RemoteRequestSender(client: client, encoder: encoder, decoder: decoder)
    }

    public func fetchTimeline(token: String) async throws -> [FeedPost] {
        let dto = try await sender.send(
            path: ClosetSocialEndpoint.timeline,
            method: .get,
            token: token,
            as: TimelineResponseDTO.self
        )
        return dto.items.map { $0.toDomain() }
    }

    public func fetchForYou(token: String) async throws -> [FeedPost] {
        let dto = try await sender.send(
            path: ClosetSocialEndpoint.timelineForYou,
            method: .get,
            token: token,
            as: TimelineResponseDTO.self
        )
        return dto.items.map { $0.toDomain() }
    }

    public func fetchDiscovery(token: String) async throws -> [FeedPost] {
        let dto = try await sender.send(
            path: ClosetSocialEndpoint.discover,
            method: .get,
            token: token,
            as: TimelineResponseDTO.self
        )
        return dto.items.map { $0.toDomain() }
    }

    public func createPost(token: String, request: CreatePostRequest) async throws -> FeedPost {
        let dto = try await sender.send(
            path: ClosetSocialEndpoint.posts,
            method: .post,
            body: request.toDTO(),
            token: token,
            as: FeedPostDTO.self
        )
        return dto.toDomain()
    }

    public func likePost(token: String, postID: UUID) async throws {
        try await sender.sendVoid(
            path: ClosetSocialEndpoint.postLike(id: postID),
            method: .post,
            token: token
        )
    }

    public func unlikePost(token: String, postID: UUID) async throws {
        try await sender.sendVoid(
            path: ClosetSocialEndpoint.postLike(id: postID),
            method: .delete,
            token: token
        )
    }

    public func savePost(token: String, postID: UUID) async throws {
        try await sender.sendVoid(
            path: ClosetSocialEndpoint.postSave(id: postID),
            method: .post,
            token: token
        )
    }

    public func unsavePost(token: String, postID: UUID) async throws {
        try await sender.sendVoid(
            path: ClosetSocialEndpoint.postSave(id: postID),
            method: .delete,
            token: token
        )
    }

    public func fetchComments(token: String, postID: UUID) async throws -> [Comment] {
        let dto = try await sender.send(
            path: ClosetSocialEndpoint.postComments(id: postID),
            method: .get,
            token: token,
            as: CommentsResponseDTO.self
        )
        return dto.items.map { $0.toDomain() }
    }

    public func createComment(token: String, postID: UUID, request: CreateCommentRequest) async throws -> Comment {
        let dto = try await sender.send(
            path: ClosetSocialEndpoint.postComments(id: postID),
            method: .post,
            body: CreateCommentRequestDTO(text: request.text),
            token: token,
            as: CommentDTO.self
        )
        return dto.toDomain()
    }
}
