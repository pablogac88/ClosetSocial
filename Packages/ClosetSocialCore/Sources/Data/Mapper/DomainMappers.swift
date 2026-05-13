import Foundation
import Domain

extension UserDTO {
    func toDomain() -> User {
        User(
            id: id,
            username: username,
            displayName: displayName,
            avatarURL: avatarURL.flatMap(URL.init(string:))
        )
    }
}

extension AuthSessionDTO {
    func toDomain() -> AuthSession {
        AuthSession(token: token, user: user.toDomain())
    }
}

extension FeedPostDTO {
    func toDomain() -> FeedPost {
        FeedPost(
            id: id,
            author: author.toDomain(),
            kind: FeedPostKind(rawValue: kind) ?? .post,
            caption: caption,
            garmentName: garmentName,
            imageURL: imageURL.flatMap(URL.init(string:)),
            createdAt: createdAt
        )
    }
}

extension GarmentDTO {
    func toDomain() -> Garment {
        Garment(
            id: id,
            name: name,
            brand: brand,
            category: category,
            color: color
        )
    }
}

extension OutfitDTO {
    func toDomain() -> Outfit {
        Outfit(
            id: id,
            title: title,
            note: note,
            garmentNames: garmentNames,
            createdAt: createdAt
        )
    }
}

extension UserProfileDTO {
    func toDomain() -> UserProfile {
        UserProfile(
            user: user.toDomain(),
            followerCount: followerCount,
            followingCount: followingCount,
            closetCount: closetCount,
            outfitCount: outfitCount
        )
    }
}

extension NewGarment {
    func toDTO() -> CreateGarmentRequestDTO {
        CreateGarmentRequestDTO(
            name: name,
            brand: brand,
            category: category,
            color: color
        )
    }
}
