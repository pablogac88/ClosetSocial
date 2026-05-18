import Foundation

/// Repositorios en memoria pensados para SwiftUI Previews y tests rápidos.
/// No usar en producción.
public actor InMemoryClosetSocialBackend {
    public static let sampleSession = AuthSession(
        token: "preview-token",
        user: User(
            id: UUID(),
            username: "pablogarcia",
            displayName: "Pablo García",
            avatarURL: nil
        )
    )

    private var session: AuthSession
    private var closet: [Garment]
    private var outfits: [Outfit]
    private var timeline: [FeedPost]
    private var comments: [UUID: [Comment]] = [:]

    public init() {
        let session = Self.sampleSession
        let oxford = Garment(
            id: UUID(),
            name: "Camisa Oxford",
            brand: "Uniqlo",
            type: .shirt,
            color: "Azul",
            imageURL: nil,
            createdAt: .now
        )
        let baseOutfit = Outfit(
            id: UUID(),
            title: "Base clean",
            note: "Mock outfit",
            garments: [oxford],
            createdAt: .now
        )
        self.session = session
        self.closet = [oxford]
        self.outfits = [baseOutfit]
        self.timeline = [
            FeedPost(
                id: UUID(),
                author: session.user,
                kind: .outfit,
                caption: "Primer look compartido desde el mock local.",
                outfit: baseOutfit,
                garment: nil,
                imageURLs: [],
                likesCount: 0,
                isLikedByCurrentUser: false,
                isSavedByCurrentUser: false,
                commentsCount: 0,
                isReal: false,
                createdAt: .now
            )
        ]
    }

    func currentSession() -> AuthSession { session }
    func currentCloset() -> [Garment] { closet }
    func currentOutfits() -> [Outfit] { outfits }
    func currentTimeline() -> [FeedPost] { timeline }

    func updateProfile(displayName: String, bio: String?, avatarURL: String?) -> UserProfile {
        let updatedUser = User(
            id: session.user.id,
            username: session.user.username,
            displayName: displayName,
            avatarURL: avatarURL.flatMap(URL.init(string:)),
            bio: bio
        )
        session = AuthSession(token: session.token, user: updatedUser)
        return UserProfile(
            user: updatedUser,
            closetCount: closet.count,
            outfitCount: outfits.count,
            postsCount: timeline.filter { $0.author.id == updatedUser.id && $0.isReal }.count,
            followerCount: 0,
            followingCount: 0
        )
    }

    func search(query: String) -> SearchResults {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return SearchResults(users: [], garments: [], outfits: [])
        }

        let normalizedQuery = normalized(trimmed)

        let users = uniqueUsers().filter { user in
            normalized(user.displayName).contains(normalizedQuery)
                || normalized(user.username).contains(normalizedQuery)
        }

        let garments = closet.filter { garment in
            normalized(garment.name).contains(normalizedQuery)
                || normalized(garment.brand).contains(normalizedQuery)
                || normalized(garment.type.displayName).contains(normalizedQuery)
                || normalized(garment.color).contains(normalizedQuery)
        }

        let outfits = outfits.filter { outfit in
            normalized(outfit.title).contains(normalizedQuery)
                || normalized(outfit.note).contains(normalizedQuery)
        }

        return SearchResults(users: users, garments: garments, outfits: outfits)
    }

    func register(username: String, displayName: String) -> AuthSession {
        let user = User(id: UUID(), username: username, displayName: displayName, avatarURL: nil)
        session = AuthSession(token: "preview-token", user: user)
        return session
    }

    func createPost(_ request: CreatePostRequest) -> FeedPost {
        let garmentsByID = Dictionary(uniqueKeysWithValues: closet.map { ($0.id, $0) })
        let outfitsByID = Dictionary(uniqueKeysWithValues: outfits.map { ($0.id, $0) })
        let garment = request.garmentID.flatMap { garmentsByID[$0] }
        let outfit = request.outfitID.flatMap { outfitsByID[$0] }
        let kind: FeedPostKind = request.outfitID != nil ? .outfit
            : (request.garmentID != nil ? .garment : .post)
        let post = FeedPost(
            id: UUID(),
            author: session.user,
            kind: kind,
            caption: request.caption,
            outfit: outfit,
            garment: garment,
            imageURLs: request.imageURLs.compactMap(URL.init(string:)),
            likesCount: 0,
            isLikedByCurrentUser: false,
            isSavedByCurrentUser: false,
            commentsCount: 0,
            isReal: true,
            createdAt: .now
        )
        timeline.insert(post, at: 0)
        return post
    }

    func toggleLike(postID: UUID) {
        guard let index = timeline.firstIndex(where: { $0.id == postID }) else { return }
        timeline[index] = timeline[index].togglingLike()
    }

    func createOutfit(_ request: CreateOutfitRequest) -> Outfit {
        let garmentsByID = Dictionary(uniqueKeysWithValues: closet.map { ($0.id, $0) })
        let selectedGarments = request.garmentIDs.compactMap { garmentsByID[$0] }
        let outfit = Outfit(
            id: UUID(),
            title: request.title,
            note: request.note,
            garments: selectedGarments,
            createdAt: .now
        )
        outfits.insert(outfit, at: 0)
        return outfit
    }

    func addGarment(_ new: NewGarment) -> Garment {
        let garment = Garment(
            id: UUID(),
            name: new.name,
            brand: new.brand,
            type: new.type,
            color: new.color,
            imageURL: new.imageURL,
            createdAt: .now
        )
        closet.insert(garment, at: 0)
        timeline.insert(
            FeedPost(
                id: UUID(),
                author: session.user,
                kind: .purchase,
                caption: "\(session.user.displayName) ha compartido una compra nueva.",
                outfit: nil,
                garment: garment,
                imageURLs: garment.imageURL.map { [$0] } ?? [],
                likesCount: 0,
                isLikedByCurrentUser: false,
                isSavedByCurrentUser: false,
                commentsCount: 0,
                isReal: false,
                createdAt: .now
            ),
            at: 0
        )
        return garment
    }

    func deleteGarment(id: UUID) throws {
        guard !outfits.contains(where: { outfit in
            outfit.garments.contains(where: { $0.id == id })
        }) else {
            throw DomainError.transport(.server(
                message: "Esta prenda pertenece a un outfit. Elimínala primero del outfit antes de borrarla del armario."
            ))
        }

        closet.removeAll { $0.id == id }
        timeline.removeAll { post in
            post.id == id || post.garment?.id == id
        }
    }

    func deleteOutfit(id: UUID) {
        outfits.removeAll { $0.id == id }
        timeline.removeAll { post in
            post.id == id || post.outfit?.id == id
        }
    }

    func fetchComments(postID: UUID) -> [Comment] {
        comments[postID] ?? []
    }

    func addComment(postID: UUID, text: String) -> Comment {
        let comment = Comment(
            id: UUID(),
            author: session.user,
            text: text,
            createdAt: .now
        )
        comments[postID, default: []].append(comment)
        if let index = timeline.firstIndex(where: { $0.id == postID }) {
            timeline[index] = timeline[index].incrementingCommentCount()
        }
        return comment
    }

    private func uniqueUsers() -> [User] {
        var seen = Set<UUID>()
        return timeline.compactMap { post in
            let author = post.author
            guard seen.insert(author.id).inserted else { return nil }
            return author
        }
    }

    private func normalized(_ value: String?) -> String {
        value?
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased() ?? ""
    }
}

public struct InMemoryAuthRepository: AuthRepository {
    private let backend: InMemoryClosetSocialBackend

    public init(backend: InMemoryClosetSocialBackend) {
        self.backend = backend
    }

    public func login(email: String, password: String) async throws -> AuthSession {
        await backend.currentSession()
    }

    public func register(
        username: String,
        displayName: String,
        email: String,
        password: String
    ) async throws -> AuthSession {
        await backend.register(username: username, displayName: displayName)
    }
}

public struct InMemoryTimelineRepository: TimelineRepository {
    private let backend: InMemoryClosetSocialBackend

    public init(backend: InMemoryClosetSocialBackend) {
        self.backend = backend
    }

    public func fetchTimeline(token: String) async throws -> [FeedPost] {
        await backend.currentTimeline()
    }

    public func fetchForYou(token: String) async throws -> [FeedPost] {
        await backend.currentTimeline()
    }

    public func fetchDiscovery(token: String) async throws -> [FeedPost] {
        await backend.currentTimeline()
    }

    public func createPost(token: String, request: CreatePostRequest) async throws -> FeedPost {
        await backend.createPost(request)
    }

    public func likePost(token: String, postID: UUID) async throws {
        await backend.toggleLike(postID: postID)
    }

    public func unlikePost(token: String, postID: UUID) async throws {
        await backend.toggleLike(postID: postID)
    }

    public func savePost(token: String, postID: UUID) async throws {}
    public func unsavePost(token: String, postID: UUID) async throws {}

    public func fetchComments(token: String, postID: UUID) async throws -> [Comment] {
        await backend.fetchComments(postID: postID)
    }

    public func createComment(token: String, postID: UUID, request: CreateCommentRequest) async throws -> Comment {
        await backend.addComment(postID: postID, text: request.text)
    }
}

public struct InMemoryClosetRepository: ClosetRepository, CatalogRepository {
    private let backend: InMemoryClosetSocialBackend

    public init(backend: InMemoryClosetSocialBackend) {
        self.backend = backend
    }

    public func fetchCloset(token: String) async throws -> [Garment] {
        await backend.currentCloset()
    }

    public func fetchGarmentTypes(token: String) async throws -> [GarmentType] {
        GarmentType.defaultOptions
    }

    public func fetchGarmentCategories(token: String) async throws -> [GarmentCategory] {
        GarmentCategory.defaultCategories
    }

    public func fetchBrands(token: String) async throws -> [Brand] {
        []
    }

    public func createGarment(token: String, garment: NewGarment) async throws -> Garment {
        await backend.addGarment(garment)
    }

    public func deleteGarment(token: String, id: UUID) async throws {
        try await backend.deleteGarment(id: id)
    }
}

public struct InMemorySearchRepository: SearchRepository {
    private let backend: InMemoryClosetSocialBackend

    public init(backend: InMemoryClosetSocialBackend) {
        self.backend = backend
    }

    public func search(token: String, query: String) async throws -> SearchResults {
        await backend.search(query: query)
    }
}

public struct InMemoryOutfitsRepository: OutfitsRepository {
    private let backend: InMemoryClosetSocialBackend

    public init(backend: InMemoryClosetSocialBackend) {
        self.backend = backend
    }

    public func fetchOutfits(token: String) async throws -> [Outfit] {
        await backend.currentOutfits()
    }

    public func createOutfit(token: String, request: CreateOutfitRequest) async throws -> Outfit {
        await backend.createOutfit(request)
    }

    public func fetchSavedOutfits(token: String) async throws -> [Outfit] { [] }
    public func deleteOutfit(token: String, id: UUID) async throws {
        await backend.deleteOutfit(id: id)
    }
    public func saveOutfit(token: String, id: UUID) async throws {}
    public func unsaveOutfit(token: String, id: UUID) async throws {}
}

public struct InMemoryNotificationRepository: NotificationRepository {
    public init() { }
    public func fetchNotifications(token: String) async throws -> [AppNotification] { [] }
    public func markRead(id: UUID, token: String) async throws { }
    public func markAllRead(token: String) async throws { }
}

public struct InMemoryProfileRepository: ProfileRepository {
    private let backend: InMemoryClosetSocialBackend

    public init(backend: InMemoryClosetSocialBackend) {
        self.backend = backend
    }

    public func fetchProfile(token: String) async throws -> UserProfile {
        let session = await backend.currentSession()
        let closet = await backend.currentCloset()
        let outfits = await backend.currentOutfits()
        let timeline = await backend.currentTimeline()
        let postsCount = timeline.filter { $0.author.id == session.user.id && $0.isReal }.count
        return UserProfile(
            user: session.user,
            closetCount: closet.count,
            outfitCount: outfits.count,
            postsCount: postsCount,
            followerCount: 0,
            followingCount: 0
        )
    }

    public func fetchPublicProfile(userID: UUID, token: String) async throws -> PublicUserProfile {
        let session = await backend.currentSession()
        let closet = await backend.currentCloset()
        let outfits = await backend.currentOutfits()
        let timeline = await backend.currentTimeline()
        let userPosts = timeline.filter { $0.author.id == userID && $0.isReal }
        return PublicUserProfile(
            user: session.user,
            closetCount: closet.count,
            outfitCount: outfits.count,
            postsCount: userPosts.count,
            posts: userPosts,
            followerCount: 0,
            followingCount: 0,
            isFollowing: false
        )
    }

    public func fetchFollowers(userID: UUID, token: String) async throws -> [User] { [] }
    public func fetchFollowing(userID: UUID, token: String) async throws -> [User] { [] }
    public func follow(userID: UUID, token: String) async throws {}
    public func unfollow(userID: UUID, token: String) async throws {}
    public func updateProfile(
        displayName: String,
        bio: String?,
        avatarURL: String?,
        token: String
    ) async throws -> UserProfile {
        await backend.updateProfile(displayName: displayName, bio: bio, avatarURL: avatarURL)
    }
}

public struct InMemoryUploadRepository: UploadRepository {
    public init() {}
    public func uploadImage(_ data: Data, mimeType: String, token: String) async throws -> URL {
        URL(string: "https://example.com/uploads/preview.jpg")!
    }
}
