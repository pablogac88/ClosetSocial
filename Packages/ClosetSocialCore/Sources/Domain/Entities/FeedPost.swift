import Foundation

public enum FeedPostKind: String, Sendable, Hashable {
    case outfit
    case purchase
    case post
}

public struct FeedPost: Sendable, Hashable, Identifiable {
    public let id: UUID
    public let author: User
    public let kind: FeedPostKind
    public let caption: String
    public let garmentName: String?
    public let imageURL: URL?
    public let createdAt: Date

    public init(
        id: UUID,
        author: User,
        kind: FeedPostKind,
        caption: String,
        garmentName: String?,
        imageURL: URL?,
        createdAt: Date
    ) {
        self.id = id
        self.author = author
        self.kind = kind
        self.caption = caption
        self.garmentName = garmentName
        self.imageURL = imageURL
        self.createdAt = createdAt
    }
}
