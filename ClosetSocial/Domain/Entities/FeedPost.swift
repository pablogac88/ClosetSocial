import Foundation

// TODO: Move to its own file (Domain/Entities/Comment.swift) once the project is more stable.
public struct Comment: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let author: User
    public let text: String
    public let createdAt: Date

    public init(id: UUID, author: User, text: String, createdAt: Date) {
        self.id = id
        self.author = author
        self.text = text
        self.createdAt = createdAt
    }
}

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
    public let likesCount: Int
    public let isLikedByCurrentUser: Bool
    public let commentsCount: Int
    public let isReal: Bool
    public let createdAt: Date

    public init(
        id: UUID,
        author: User,
        kind: FeedPostKind,
        caption: String,
        outfit: Outfit?,
        garment: Garment?,
        imageURLs: [URL],
        likesCount: Int,
        isLikedByCurrentUser: Bool,
        commentsCount: Int,
        isReal: Bool,
        createdAt: Date
    ) {
        self.id = id
        self.author = author
        self.kind = kind
        self.caption = caption
        self.outfit = outfit
        self.garment = garment
        self.imageURLs = imageURLs
        self.likesCount = likesCount
        self.isLikedByCurrentUser = isLikedByCurrentUser
        self.commentsCount = commentsCount
        self.isReal = isReal
        self.createdAt = createdAt
    }

    /// Returns a copy with the like state toggled (for optimistic updates).
    func togglingLike() -> FeedPost {
        FeedPost(
            id: id, author: author, kind: kind, caption: caption,
            outfit: outfit, garment: garment, imageURLs: imageURLs,
            likesCount: isLikedByCurrentUser ? max(0, likesCount - 1) : likesCount + 1,
            isLikedByCurrentUser: !isLikedByCurrentUser,
            commentsCount: commentsCount,
            isReal: isReal, createdAt: createdAt
        )
    }

    /// Returns a copy with commentsCount incremented by one (for optimistic updates).
    func incrementingCommentCount() -> FeedPost {
        FeedPost(
            id: id, author: author, kind: kind, caption: caption,
            outfit: outfit, garment: garment, imageURLs: imageURLs,
            likesCount: likesCount, isLikedByCurrentUser: isLikedByCurrentUser,
            commentsCount: commentsCount + 1,
            isReal: isReal, createdAt: createdAt
        )
    }
}
