import Foundation

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
            outfit: outfit?.toDomain(),
            garment: garment?.toDomain() ?? garmentName.map(Self.makeLegacyGarment),
            imageURLs: resolvedImageURLs,
            createdAt: createdAt
        )
    }

    private var resolvedImageURLs: [URL] {
        if let imageURLs {
            return imageURLs.compactMap(URL.init(string:))
        }
        if let imageURL = imageURL.flatMap(URL.init(string:)) {
            return [imageURL]
        }
        return []
    }

    private static func makeLegacyGarment(named name: String) -> Garment {
        Garment(
            id: UUID(),
            name: name,
            brand: nil,
            type: .other,
            color: "",
            imageURL: nil,
            createdAt: .now
        )
    }
}

extension GarmentDTO {
    func toDomain() -> Garment {
        Garment(
            id: id,
            name: name,
            brand: brand,
            type: type,
            color: color,
            imageURL: imageURL.flatMap(URL.init(string:)),
            createdAt: createdAt ?? .now
        )
    }
}

extension OutfitDTO {
    func toDomain() -> Outfit {
        Outfit(
            id: id,
            title: title?.trimmedToNil,
            note: note?.trimmedToNil,
            garments: resolvedGarments,
            createdAt: createdAt
        )
    }

    private var resolvedGarments: [Garment] {
        if let garments {
            return garments.map { $0.toDomain() }
        }

        return (garmentNames ?? []).map { name in
            Garment(
                id: UUID(),
                name: name,
                brand: nil,
                type: .other,
                color: "",
                imageURL: nil,
                createdAt: createdAt
            )
        }
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
            type: type,
            color: color,
            imageURL: imageURL?.absoluteString
        )
    }
}

private extension String {
    var trimmedToNil: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
