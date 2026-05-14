import Foundation

extension UserDTO {
    func toDomain() -> User {
        User(
            id: id,
            username: username,
            displayName: displayName,
            avatarURL: avatarURL.flatMap(URL.init(string:)),
            bio: bio,
            role: role ?? .user
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
            garment: garment?.toDomain(),
            imageURLs: imageURLs?.compactMap(URL.init(string:)) ?? [],
            likesCount: likesCount ?? 0,
            isLikedByCurrentUser: isLikedByCurrentUser ?? false,
            commentsCount: commentsCount ?? 0,
            isReal: isReal ?? false,
            createdAt: createdAt
        )
    }
}

extension CommentDTO {
    func toDomain() -> Comment {
        Comment(id: id, author: author.toDomain(), text: text, createdAt: createdAt)
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
            layout: decodedLayout,
            createdAt: createdAt
        )
    }

    private var decodedLayout: OutfitComposerLayout? {
        guard let json = layoutJSON, let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(OutfitComposerLayout.self, from: data)
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
            closetCount: closetCount,
            outfitCount: outfitCount,
            postsCount: postsCount
        )
    }
}

extension PublicUserProfileDTO {
    func toDomain() -> PublicUserProfile {
        PublicUserProfile(
            user: user.toDomain(),
            closetCount: closetCount,
            outfitCount: outfitCount,
            postsCount: postsCount,
            posts: recentPosts.map { $0.toDomain() }
        )
    }
}

extension CreatePostRequest {
    func toDTO() -> CreatePostRequestDTO {
        CreatePostRequestDTO(
            caption: caption,
            outfitID: outfitID,
            garmentID: garmentID,
            imageURLs: imageURLs
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
