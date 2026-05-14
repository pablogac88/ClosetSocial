import Foundation

public protocol TimelineRepository: Sendable {
    func fetchTimeline(token: String) async throws -> [FeedPost]
    func fetchDiscovery(token: String) async throws -> [FeedPost]
    func createPost(token: String, request: CreatePostRequest) async throws -> FeedPost
    func likePost(token: String, postID: UUID) async throws
    func unlikePost(token: String, postID: UUID) async throws
    func fetchComments(token: String, postID: UUID) async throws -> [Comment]
    func createComment(token: String, postID: UUID, request: CreateCommentRequest) async throws -> Comment
}

public struct CreateCommentRequest: Sendable {
    public let text: String

    public init(text: String) {
        self.text = text
    }
}

public struct CreatePostRequest: Sendable {
    public let caption: String
    public let outfitID: UUID?
    public let garmentID: UUID?
    public let imageURLs: [String]

    public init(caption: String, outfitID: UUID?, garmentID: UUID?, imageURLs: [String]) {
        self.caption = caption
        self.outfitID = outfitID
        self.garmentID = garmentID
        self.imageURLs = imageURLs
    }
}
