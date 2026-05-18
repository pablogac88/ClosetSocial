import Foundation

public struct ExploreOutfitItem: Sendable, Equatable, Identifiable {
    public let outfit: Outfit
    public let author: User

    public var id: UUID { outfit.id }

    public init(outfit: Outfit, author: User) {
        self.outfit = outfit
        self.author = author
    }
}

public struct ExploreGarmentItem: Sendable, Equatable, Identifiable {
    public let garment: Garment
    public let owner: User?

    public var id: UUID { garment.id }

    public init(garment: Garment, owner: User?) {
        self.garment = garment
        self.owner = owner
    }
}

public struct ExploreUserItem: Sendable, Equatable, Identifiable {
    public let user: User
    public let closetCount: Int
    public let outfitCount: Int
    public let postsCount: Int
    public let followerCount: Int
    public let followingCount: Int
    public let isFollowing: Bool

    public var id: UUID { user.id }

    public init(
        user: User,
        closetCount: Int,
        outfitCount: Int,
        postsCount: Int,
        followerCount: Int,
        followingCount: Int,
        isFollowing: Bool
    ) {
        self.user = user
        self.closetCount = closetCount
        self.outfitCount = outfitCount
        self.postsCount = postsCount
        self.followerCount = followerCount
        self.followingCount = followingCount
        self.isFollowing = isFollowing
    }

    public func togglingFollow() -> ExploreUserItem {
        ExploreUserItem(
            user: user,
            closetCount: closetCount,
            outfitCount: outfitCount,
            postsCount: postsCount,
            followerCount: isFollowing ? max(0, followerCount - 1) : followerCount + 1,
            followingCount: followingCount,
            isFollowing: !isFollowing
        )
    }
}

public struct ExploreSearchResults: Sendable, Equatable {
    public let outfits: [ExploreOutfitItem]
    public let garments: [ExploreGarmentItem]
    public let users: [ExploreUserItem]

    public init(
        outfits: [ExploreOutfitItem],
        garments: [ExploreGarmentItem],
        users: [ExploreUserItem]
    ) {
        self.outfits = outfits
        self.garments = garments
        self.users = users
    }

    public var isEmpty: Bool {
        outfits.isEmpty && garments.isEmpty && users.isEmpty
    }
}

public struct SearchResults: Sendable, Equatable {
    public let users: [User]
    public let garments: [Garment]
    public let outfits: [Outfit]

    public init(users: [User], garments: [Garment], outfits: [Outfit]) {
        self.users = users
        self.garments = garments
        self.outfits = outfits
    }

    public var isEmpty: Bool {
        users.isEmpty && garments.isEmpty && outfits.isEmpty
    }
}
