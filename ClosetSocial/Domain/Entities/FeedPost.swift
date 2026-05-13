import Foundation

public enum FeedPostKind: String, Codable, Sendable, Equatable {
    case outfit
    case garment
    case purchase
    case post
}

public struct FeedPost: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let author: User
    public let kind: FeedPostKind
    public let caption: String
    public let outfit: Outfit?
    public let garment: Garment?
    public let imageURLs: [URL]
    public let createdAt: Date

    public init(
        id: UUID,
        author: User,
        kind: FeedPostKind,
        caption: String,
        outfit: Outfit?,
        garment: Garment?,
        imageURLs: [URL],
        createdAt: Date
    ) {
        self.id = id
        self.author = author
        self.kind = kind
        self.caption = caption
        self.outfit = outfit
        self.garment = garment
        self.imageURLs = imageURLs
        self.createdAt = createdAt
    }
}
