import Foundation

struct UserProfileDTO: Codable, Sendable, Equatable {
    let user: UserDTO
    let followerCount: Int
    let followingCount: Int
    let closetCount: Int
    let outfitCount: Int
}
