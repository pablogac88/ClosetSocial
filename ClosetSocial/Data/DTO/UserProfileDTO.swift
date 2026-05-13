import Foundation

struct UserProfileDTO: Codable, Sendable, Equatable {
    let user: UserDTO
    let closetCount: Int
    let outfitCount: Int
    let postsCount: Int
}

struct PublicUserProfileDTO: Codable, Sendable, Equatable {
    let user: UserDTO
    let closetCount: Int
    let outfitCount: Int
    let postsCount: Int
    let recentPosts: [FeedPostDTO]
}
