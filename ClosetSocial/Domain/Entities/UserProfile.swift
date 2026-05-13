import Foundation

public struct UserProfile: Codable, Sendable, Equatable {
    public let user: User
    public var followerCount: Int
    public var followingCount: Int
    public var closetCount: Int
    public var outfitCount: Int

    public init(
        user: User,
        followerCount: Int,
        followingCount: Int,
        closetCount: Int,
        outfitCount: Int
    ) {
        self.user = user
        self.followerCount = followerCount
        self.followingCount = followingCount
        self.closetCount = closetCount
        self.outfitCount = outfitCount
    }
}
