import Foundation
import Observation

public enum TimelineState: Sendable {
    case idle
    case loading
    case content([FeedPost])
    case empty
    case error(String)
}

public enum TimelineTab: String, CaseIterable, Sendable {
    case forYou    = "Para ti"
    case following = "Siguiendo"
}

public enum CommentsState: Sendable {
    case idle
    case loading
    case content([Comment])
    case empty
    case error(String)
}

@MainActor
@Observable
public final class TimelineViewModel {
    public typealias TokenProvider = @MainActor () -> String?

    public var selectedTab: TimelineTab = .forYou
    public private(set) var forYouState: TimelineState = .idle
    public private(set) var followingState: TimelineState = .idle
    public private(set) var availableGarments: [Garment] = []
    public private(set) var availableOutfits: [Outfit] = []
    public private(set) var isCreatingPost = false
    public var createPostError: String?
    public private(set) var commentsState: CommentsState = .idle
    public private(set) var isCreatingComment = false
    public var createCommentError: String?
    private var pendingLikes: Set<UUID> = []

    public var activeState: TimelineState {
        selectedTab == .forYou ? forYouState : followingState
    }

    // Legacy accessor kept for external callers (replace, replacePost).
    public var state: TimelineState {
        get { followingState }
        set { followingState = newValue }
    }

    private let repository: any TimelineRepository
    private let closetRepository: any ClosetRepository
    private let outfitsRepository: any OutfitsRepository
    private let tokenProvider: TokenProvider

    public init(
        repository: any TimelineRepository,
        closetRepository: any ClosetRepository,
        outfitsRepository: any OutfitsRepository,
        tokenProvider: @escaping TokenProvider
    ) {
        self.repository = repository
        self.closetRepository = closetRepository
        self.outfitsRepository = outfitsRepository
        self.tokenProvider = tokenProvider
    }

    public func load() async {
        async let forYou: Void = loadForYou()
        async let following: Void = loadFollowing()
        _ = await (forYou, following)
    }

    public func loadActiveTab() async {
        switch selectedTab {
        case .forYou:    await loadForYou()
        case .following: await loadFollowing()
        }
    }

    public func loadForYou() async {
        guard let token = tokenProvider() else {
            forYouState = .error(DomainError.unauthenticated.userMessage)
            return
        }
        forYouState = .loading
        do {
            let items = try await repository.fetchForYou(token: token)
            forYouState = items.isEmpty ? .empty : .content(items)
        } catch {
            forYouState = .error(error.userMessage)
        }
    }

    public func loadFollowing() async {
        guard let token = tokenProvider() else {
            followingState = .error(DomainError.unauthenticated.userMessage)
            return
        }
        followingState = .loading
        do {
            let items = try await repository.fetchTimeline(token: token)
            followingState = items.isEmpty ? .empty : .content(items)
        } catch {
            followingState = .error(error.userMessage)
        }
    }

    public func loadAvailableContent() async {
        guard let token = tokenProvider() else { return }
        async let garmentsTask = (try? await closetRepository.fetchCloset(token: token)) ?? []
        async let outfitsTask = (try? await outfitsRepository.fetchOutfits(token: token)) ?? []
        let (garments, outfits) = await (garmentsTask, outfitsTask)
        availableGarments = garments
        availableOutfits = outfits
    }

    public func createPost(
        caption: String,
        outfitID: UUID?,
        garmentID: UUID?,
        imageURLs: [String] = []
    ) async {
        guard let token = tokenProvider() else {
            createPostError = DomainError.unauthenticated.userMessage
            return
        }
        isCreatingPost = true
        createPostError = nil
        defer { isCreatingPost = false }

        let request = CreatePostRequest(
            caption: caption,
            outfitID: outfitID,
            garmentID: garmentID,
            imageURLs: imageURLs
        )
        do {
            let post = try await repository.createPost(token: token, request: request)
            switch followingState {
            case let .content(items): followingState = .content([post] + items)
            default: followingState = .content([post])
            }
            switch forYouState {
            case let .content(items): forYouState = .content([post] + items)
            default: break
            }
        } catch {
            createPostError = error.userMessage
        }
    }

    public func loadComments(for post: FeedPost) async {
        guard let token = tokenProvider() else {
            commentsState = .error(DomainError.unauthenticated.userMessage)
            return
        }
        commentsState = .loading
        createCommentError = nil
        do {
            let items = try await repository.fetchComments(token: token, postID: post.id)
            commentsState = items.isEmpty ? .empty : .content(items)
        } catch {
            commentsState = .error(error.userMessage)
        }
    }

    public func createComment(for post: FeedPost, text: String) async {
        guard let token = tokenProvider() else {
            createCommentError = DomainError.unauthenticated.userMessage
            return
        }
        // Resolve the latest snapshot from feed state to keep commentsCount accurate
        // across multiple sequential submissions within the same sheet session.
        let currentPost: FeedPost
        let activeItems: [FeedPost]? = {
            if case let .content(items) = followingState { return items }
            if case let .content(items) = forYouState { return items }
            return nil
        }()
        if let found = activeItems?.first(where: { $0.id == post.id }) {
            currentPost = found
        } else {
            currentPost = post
        }

        isCreatingComment = true
        createCommentError = nil
        defer { isCreatingComment = false }

        replacePost(currentPost.incrementingCommentCount())
        do {
            let comment = try await repository.createComment(
                token: token,
                postID: post.id,
                request: CreateCommentRequest(text: text)
            )
            switch commentsState {
            case let .content(existing): commentsState = .content(existing + [comment])
            default: commentsState = .content([comment])
            }
        } catch {
            replacePost(currentPost)
            createCommentError = error.userMessage
        }
    }

    public func findPost(id: UUID) -> FeedPost? {
        if case let .content(items) = activeState,
           let post = items.first(where: { $0.id == id }) { return post }
        if case let .content(items) = forYouState,
           let post = items.first(where: { $0.id == id }) { return post }
        if case let .content(items) = followingState,
           let post = items.first(where: { $0.id == id }) { return post }
        return nil
    }

    public func toggleLike(for post: FeedPost) async {
        guard post.isReal, let token = tokenProvider() else { return }
        guard !pendingLikes.contains(post.id) else { return }
        pendingLikes.insert(post.id)
        defer { pendingLikes.remove(post.id) }

        replacePost(post.togglingLike())
        do {
            if post.isLikedByCurrentUser {
                try await repository.unlikePost(token: token, postID: post.id)
            } else {
                try await repository.likePost(token: token, postID: post.id)
            }
        } catch {
            replacePost(post)
        }
    }

    public func toggleOutfitSave(for post: FeedPost) async {
        guard let outfit = post.outfit, post.isReal, let token = tokenProvider() else { return }
        replacePost(post.withOutfitSaveToggled())
        do {
            if outfit.isSavedByCurrentUser {
                try await outfitsRepository.unsaveOutfit(token: token, id: outfit.id)
            } else {
                try await outfitsRepository.saveOutfit(token: token, id: outfit.id)
            }
        } catch {
            replacePost(post)
        }
    }

    public func toggleSave(for post: FeedPost) async {
        guard post.isReal, let token = tokenProvider() else { return }
        replacePost(post.togglingSave())
        do {
            if post.isSavedByCurrentUser {
                try await repository.unsavePost(token: token, postID: post.id)
            } else {
                try await repository.savePost(token: token, postID: post.id)
            }
        } catch {
            replacePost(post)
        }
    }

    /// Permite a otras features (AddGarment) refrescar el timeline tras un cambio.
    public func replace(with items: [FeedPost]) {
        state = items.isEmpty ? .empty : .content(items)
    }

    private func replacePost(_ updated: FeedPost) {
        if case let .content(items) = forYouState {
            forYouState = .content(items.map { $0.id == updated.id ? updated : $0 })
        }
        if case let .content(items) = followingState {
            followingState = .content(items.map { $0.id == updated.id ? updated : $0 })
        }
    }
}
