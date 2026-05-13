import Foundation
import Observation

public enum TimelineState: Sendable {
    case idle
    case loading
    case content([FeedPost])
    case empty
    case error(String)
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

    public private(set) var state: TimelineState = .idle
    public private(set) var availableGarments: [Garment] = []
    public private(set) var availableOutfits: [Outfit] = []
    public private(set) var isCreatingPost = false
    public var createPostError: String?
    public private(set) var commentsState: CommentsState = .idle
    public private(set) var isCreatingComment = false
    public var createCommentError: String?
    private var pendingLikes: Set<UUID> = []

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
        guard let token = tokenProvider() else {
            state = .error(DomainError.unauthenticated.userMessage)
            return
        }
        state = .loading
        do {
            let items = try await repository.fetchTimeline(token: token)
            state = items.isEmpty ? .empty : .content(items)
        } catch {
            state = .error(error.userMessage)
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
            switch state {
            case let .content(items):
                state = .content([post] + items)
            default:
                state = .content([post])
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
        if case let .content(items) = state, let found = items.first(where: { $0.id == post.id }) {
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

    /// Permite a otras features (AddGarment) refrescar el timeline tras un cambio.
    public func replace(with items: [FeedPost]) {
        state = items.isEmpty ? .empty : .content(items)
    }

    private func replacePost(_ updated: FeedPost) {
        guard case let .content(items) = state else { return }
        state = .content(items.map { $0.id == updated.id ? updated : $0 })
    }
}
