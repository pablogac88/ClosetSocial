import Foundation
import Observation

public enum ExploreState: Sendable {
    case idle
    case loading
    case content([FeedPost])
    case empty
    case error(String)
}

enum ExploreSearchState: Sendable {
    case idle
    case loading
    case content(SearchResults)
    case empty
    case error(String)
}

struct ExplorePerson: Sendable, Equatable, Identifiable {
    let user: User
    let postsCount: Int
    let looksCount: Int
    let garmentsCount: Int
    let lastActivityAt: Date
    let spotlightCaption: String?

    var id: UUID { user.id }
}

@MainActor
@Observable
public final class ExploreViewModel {
    public typealias TokenProvider = @MainActor () -> String?

    public private(set) var state: ExploreState = .idle
    var searchState: ExploreSearchState = .idle
    public var searchText = ""

    private let editorialRepository: any TimelineRepository
    private let searchRepository: any SearchRepository
    private let tokenProvider: TokenProvider

    public init(
        editorialRepository: any TimelineRepository,
        searchRepository: any SearchRepository,
        tokenProvider: @escaping TokenProvider
    ) {
        self.editorialRepository = editorialRepository
        self.searchRepository = searchRepository
        self.tokenProvider = tokenProvider
    }

    func load(showLoadingState: Bool = true) async {
        let previousState = state
        guard let token = tokenProvider() else {
            state = .error(DomainError.unauthenticated.userMessage)
            return
        }
        if showLoadingState {
            state = .loading
        }
        do {
            let items = try await editorialRepository.fetchDiscovery(token: token)
            state = items.isEmpty ? .empty : .content(items)
        } catch is CancellationError {
            state = previousState
        } catch {
            if case .content = previousState {
                state = previousState
            } else {
                state = .error(error.userMessage)
            }
        }
    }

    func refresh() async {
        if shouldUseBackendSearch {
            await performSearch(showLoadingState: false)
        } else {
            await load(showLoadingState: false)
        }
    }

    func replace(with items: [FeedPost]) {
        state = items.isEmpty ? .empty : .content(items)
    }

    func handleSearchTextChanged() async {
        let trimmed = trimmedQuery

        if trimmed.isEmpty || trimmed.count < 2 {
            searchState = .idle
            return
        }

        await performSearch(showLoadingState: true)
    }

    var shouldUseBackendSearch: Bool {
        trimmedQuery.count >= 2
    }

    var isShortQuery: Bool {
        let count = trimmedQuery.count
        return count > 0 && count < 2
    }

    var searchResults: SearchResults? {
        guard case let .content(results) = searchState else { return nil }
        return results
    }

    var isSearching: Bool {
        if case .loading = searchState { return true }
        return false
    }

    var searchErrorMessage: String? {
        if case let .error(message) = searchState { return message }
        return nil
    }

    var outfitPosts: [FeedPost] {
        editorialPosts.filter { $0.outfit != nil }
    }

    var garmentPosts: [FeedPost] {
        editorialPosts.filter { $0.garment != nil }
    }

    var people: [ExplorePerson] {
        uniquePeople(from: editorialPosts)
    }

    var searchUsers: [User] {
        searchResults?.users ?? []
    }

    var searchGarments: [Garment] {
        searchResults?.garments ?? []
    }

    var searchOutfits: [Outfit] {
        searchResults?.outfits ?? []
    }

    func relatedOutfits(for garmentID: UUID) -> [Outfit] {
        var seen = Set<UUID>()
        var results: [Outfit] = []

        for post in editorialPosts {
            guard let outfit = post.outfit else { continue }
            guard outfit.garments.contains(where: { $0.id == garmentID }) else { continue }
            guard seen.insert(outfit.id).inserted else { continue }
            results.append(outfit)
        }

        return results
    }

    private var editorialPosts: [FeedPost] {
        guard case let .content(items) = state else { return [] }
        return items
    }

    private var trimmedQuery: String {
        normalized(searchText)
    }

    private func performSearch(showLoadingState: Bool) async {
        let query = trimmedQuery
        guard query.count >= 2 else {
            searchState = .idle
            return
        }
        guard let token = tokenProvider() else {
            searchState = .error(DomainError.unauthenticated.userMessage)
            return
        }

        if showLoadingState {
            searchState = .loading
        }

        do {
            let results = try await searchRepository.search(token: token, query: query)
            guard !Task.isCancelled, query == trimmedQuery else { return }
            searchState = results.isEmpty ? .empty : .content(results)
        } catch is CancellationError {
            // The view's .task(id:) will cancel stale searches while typing.
        } catch {
            guard query == trimmedQuery else { return }
            searchState = .error(error.userMessage)
        }
    }

    private func uniquePeople(from posts: [FeedPost]) -> [ExplorePerson] {
        var storage: [UUID: ExplorePerson] = [:]
        var order: [UUID] = []

        for post in posts {
            let userID = post.author.id
            let existing = storage[userID]
            let updated = ExplorePerson(
                user: post.author,
                postsCount: (existing?.postsCount ?? 0) + 1,
                looksCount: (existing?.looksCount ?? 0) + (post.outfit == nil ? 0 : 1),
                garmentsCount: (existing?.garmentsCount ?? 0) + (post.garment == nil ? 0 : 1),
                lastActivityAt: max(existing?.lastActivityAt ?? .distantPast, post.createdAt),
                spotlightCaption: existing?.spotlightCaption ?? post.caption.nilIfBlank
            )
            storage[userID] = updated
            if existing == nil {
                order.append(userID)
            }
        }

        return order
            .compactMap { storage[$0] }
            .sorted { lhs, rhs in
                if lhs.lastActivityAt != rhs.lastActivityAt {
                    return lhs.lastActivityAt > rhs.lastActivityAt
                }
                return lhs.postsCount > rhs.postsCount
            }
    }

    private func normalized(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}

private extension String {
    var nilIfBlank: String? {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
    }
}
