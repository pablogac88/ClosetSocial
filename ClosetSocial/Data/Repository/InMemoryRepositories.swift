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
                createdAt: .now
            )
        ]
    }

    func currentSession() -> AuthSession { session }
    func currentCloset() -> [Garment] { closet }
    func currentOutfits() -> [Outfit] { outfits }
    func currentTimeline() -> [FeedPost] { timeline }

    func register(username: String, displayName: String) -> AuthSession {
        let user = User(id: UUID(), username: username, displayName: displayName, avatarURL: nil)
        session = AuthSession(token: "preview-token", user: user)
        return session
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
                createdAt: .now
            ),
            at: 0
        )
        return garment
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
}

public struct InMemoryClosetRepository: ClosetRepository {
    private let backend: InMemoryClosetSocialBackend

    public init(backend: InMemoryClosetSocialBackend) {
        self.backend = backend
    }

    public func fetchCloset(token: String) async throws -> [Garment] {
        await backend.currentCloset()
    }

    public func createGarment(token: String, garment: NewGarment) async throws -> Garment {
        await backend.addGarment(garment)
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
        return UserProfile(
            user: session.user,
            followerCount: 12,
            followingCount: 8,
            closetCount: closet.count,
            outfitCount: outfits.count
        )
    }
}
