import Foundation

struct FeedPostDTO: Codable, Sendable, Equatable, Identifiable {
    let id: UUID
    let author: UserDTO
    let kind: String
    let caption: String
    let outfit: OutfitDTO?
    let garment: GarmentDTO?
    let imageURLs: [String]?
    let likesCount: Int?
    let isLikedByCurrentUser: Bool?
    let commentsCount: Int?
    let isReal: Bool?
    let createdAt: Date
}

struct TimelineResponseDTO: Codable, Sendable, Equatable {
    let items: [FeedPostDTO]
}

struct CreatePostRequestDTO: Encodable, Sendable {
    let caption: String
    let outfitID: UUID?
    let garmentID: UUID?
    let imageURLs: [String]
}

struct CommentDTO: Codable, Sendable, Equatable, Identifiable {
    let id: UUID
    let author: UserDTO
    let text: String
    let createdAt: Date
}

struct CommentsResponseDTO: Codable, Sendable, Equatable {
    let items: [CommentDTO]
}

struct CreateCommentRequestDTO: Encodable, Sendable {
    let text: String
}
