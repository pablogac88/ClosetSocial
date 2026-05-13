import Foundation

public struct UserProfile: Codable, Sendable, Equatable {
    public let user: User
    public let closetCount: Int
    public let outfitCount: Int
    public let postsCount: Int

    public init(user: User, closetCount: Int, outfitCount: Int, postsCount: Int) {
        self.user = user
        self.closetCount = closetCount
        self.outfitCount = outfitCount
        self.postsCount = postsCount
    }
}

/// Profile of another user, includes their public posts for the profile sheet.
public struct PublicUserProfile: Sendable, Equatable, Identifiable {
    public var id: UUID { user.id }
    public let user: User
    public let closetCount: Int
    public let outfitCount: Int
    public let postsCount: Int
    public let posts: [FeedPost]

    public init(user: User, closetCount: Int, outfitCount: Int, postsCount: Int, posts: [FeedPost]) {
        self.user = user
        self.closetCount = closetCount
        self.outfitCount = outfitCount
        self.postsCount = postsCount
        self.posts = posts
    }
}
