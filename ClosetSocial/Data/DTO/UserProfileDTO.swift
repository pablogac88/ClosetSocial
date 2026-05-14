import Foundation

struct UserProfileDTO: Codable, Sendable, Equatable {
    let user: UserDTO
    let closetCount: Int
    let outfitCount: Int
    let postsCount: Int
    let followerCount: Int
    let followingCount: Int
}

struct UpdateProfileRequestDTO: Encodable, Sendable {
    let displayName: String
    let bio: String?
    let avatarURL: String?
}

struct PublicUserProfileDTO: Codable, Sendable, Equatable {
    let user: UserDTO
    let closetCount: Int
    let outfitCount: Int
    let postsCount: Int
    let recentPosts: [FeedPostDTO]
    let followerCount: Int
    let followingCount: Int
    let isFollowing: Bool
}
