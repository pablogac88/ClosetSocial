import Foundation
import Observation

public enum ExploreTab: String, Sendable, CaseIterable, Identifiable {
    case looks = "Looks"
    case garments = "Prendas"
    case people = "Personas"

    public var id: String { rawValue }
}

public enum ExploreFeedState<Item: Sendable & Equatable>: Sendable, Equatable {
    case idle
    case loading
    case content([Item])
    case empty
    case error(String)
}

enum ExploreSearchState: Sendable, Equatable {
    case idle
    case loading
    case content(ExploreSearchResults)
    case empty
    case error(String)
}

@MainActor
@Observable
public final class ExploreViewModel {
    public typealias TokenProvider = @MainActor () -> String?
    public typealias CurrentUserIDProvider = @MainActor () -> UUID?

    public var selectedTab: ExploreTab = .looks
    public var searchText = ""

    private(set) var searchState: ExploreSearchState = .idle
    public private(set) var savingOutfitIDs: Set<UUID> = []
    public private(set) var followingUserIDs: Set<UUID> = []

    private var looksDiscoveryStateStorage: ExploreFeedState<ExploreOutfitItem> = .idle
    private var garmentsDiscoveryStateStorage: ExploreFeedState<ExploreGarmentItem> = .idle
    private var peopleDiscoveryStateStorage: ExploreFeedState<ExploreUserItem> = .idle

    private var discoverLooksCache: [ExploreOutfitItem] = []
    private var discoverGarmentsCache: [ExploreGarmentItem] = []
    private var discoverPeopleCache: [ExploreUserItem] = []

    private let repository: any ExploreRepository
    private let outfitsRepository: any OutfitsRepository
    private let profileRepository: any ProfileRepository
    private let tokenProvider: TokenProvider
    private let currentUserIDProvider: CurrentUserIDProvider
    private let discoveryLimit = 30

    public init(
        repository: any ExploreRepository,
        outfitsRepository: any OutfitsRepository,
        profileRepository: any ProfileRepository,
        tokenProvider: @escaping TokenProvider,
        currentUserIDProvider: @escaping CurrentUserIDProvider
    ) {
        self.repository = repository
        self.outfitsRepository = outfitsRepository
        self.profileRepository = profileRepository
        self.tokenProvider = tokenProvider
        self.currentUserIDProvider = currentUserIDProvider
    }

    public var looksState: ExploreFeedState<ExploreOutfitItem> {
        resolvedState(
            discoveryState: looksDiscoveryStateStorage,
            searchItems: { $0.outfits }
        )
    }

    public var garmentsState: ExploreFeedState<ExploreGarmentItem> {
        resolvedState(
            discoveryState: garmentsDiscoveryStateStorage,
            searchItems: { $0.garments }
        )
    }

    public var peopleState: ExploreFeedState<ExploreUserItem> {
        resolvedState(
            discoveryState: peopleDiscoveryStateStorage,
            searchItems: { $0.users }
        )
    }

    public var currentUserID: UUID? {
        currentUserIDProvider()
    }

    public var shouldUseBackendSearch: Bool {
        trimmedQuery.count >= 2
    }

    public var isShortQuery: Bool {
        let count = trimmedQuery.count
        return count > 0 && count < 2
    }

    public func load() async {
        await loadTabIfNeeded()
    }

    public func loadTabIfNeeded() async {
        if shouldUseBackendSearch {
            if case .idle = searchState {
                await performSearch(showLoadingState: true)
            }
            return
        }

        switch selectedTab {
        case .looks:
            if discoverLooksCache.isEmpty || isIdle(looksDiscoveryStateStorage) {
                await loadLooks(force: false)
            }
        case .garments:
            if discoverGarmentsCache.isEmpty || isIdle(garmentsDiscoveryStateStorage) {
                await loadGarments(force: false)
            }
        case .people:
            if discoverPeopleCache.isEmpty || isIdle(peopleDiscoveryStateStorage) {
                await loadPeople(force: false)
            }
        }
    }

    public func refreshSelectedTab() async {
        if shouldUseBackendSearch {
            await performSearch(showLoadingState: false)
            return
        }

        switch selectedTab {
        case .looks:
            await loadLooks(force: true)
        case .garments:
            await loadGarments(force: true)
        case .people:
            await loadPeople(force: true)
        }
    }

    public func refreshAllDiscovery() async {
        await loadLooks(force: true)
        await loadGarments(force: true)
        await loadPeople(force: true)
    }

    public func handleSearchTextChanged() async {
        if trimmedQuery.isEmpty || isShortQuery {
            searchState = .idle
            return
        }

        do {
            try await Task.sleep(for: .milliseconds(280))
        } catch {
            return
        }

        guard !Task.isCancelled else { return }
        await performSearch(showLoadingState: true)
    }

    public func toggleSave(for item: ExploreOutfitItem) async {
        guard let token = tokenProvider() else { return }
        let outfit = item.outfit
        guard savingOutfitIDs.insert(outfit.id).inserted else { return }
        defer { savingOutfitIDs.remove(outfit.id) }

        let original = item
        let optimistic = ExploreOutfitItem(
            outfit: outfit.togglingBookmark(),
            author: item.author
        )
        replaceOutfitItem(optimistic)

        do {
            if outfit.isSavedByCurrentUser {
                try await outfitsRepository.unsaveOutfit(token: token, id: outfit.id)
            } else {
                try await outfitsRepository.saveOutfit(token: token, id: outfit.id)
            }
        } catch {
            replaceOutfitItem(original)
        }
    }

    public func toggleFollow(for item: ExploreUserItem) async {
        guard let token = tokenProvider(),
              let currentUserID,
              currentUserID != item.user.id
        else { return }
        guard followingUserIDs.insert(item.id).inserted else { return }
        defer { followingUserIDs.remove(item.id) }

        let original = item
        let optimistic = item.togglingFollow()
        replaceUserItem(optimistic)

        do {
            if item.isFollowing {
                try await profileRepository.unfollow(userID: item.id, token: token)
            } else {
                try await profileRepository.follow(userID: item.id, token: token)
            }
        } catch {
            replaceUserItem(original)
        }
    }

    public func relatedOutfits(for garmentID: UUID) -> [Outfit] {
        let source = shouldUseBackendSearch ? currentSearchResults?.outfits ?? [] : discoverLooksCache
        var seen = Set<UUID>()
        return source.compactMap { item in
            guard item.outfit.garments.contains(where: { $0.id == garmentID }) else { return nil }
            guard seen.insert(item.outfit.id).inserted else { return nil }
            return item.outfit
        }
    }

    public func findOutfitItem(forOutfitID id: UUID) -> ExploreOutfitItem? {
        if let item = discoverLooksCache.first(where: { $0.id == id }) { return item }
        if let item = currentSearchResults?.outfits.first(where: { $0.id == id }) { return item }
        return nil
    }

    public func isSaving(_ item: ExploreOutfitItem) -> Bool {
        savingOutfitIDs.contains(item.id)
    }

    public func isFollowingLoading(_ item: ExploreUserItem) -> Bool {
        followingUserIDs.contains(item.id)
    }

    private var trimmedQuery: String {
        searchText
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private var currentSearchResults: ExploreSearchResults? {
        guard case let .content(results) = searchState else { return nil }
        return results
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
            let results = try await repository.search(token: token, query: query)
            guard query == trimmedQuery, !Task.isCancelled else { return }
            searchState = results.isEmpty ? .empty : .content(results)
        } catch is CancellationError {
            return
        } catch {
            guard query == trimmedQuery else { return }
            searchState = .error(error.userMessage)
        }
    }

    private func loadLooks(force: Bool) async {
        if !force, !discoverLooksCache.isEmpty {
            looksDiscoveryStateStorage = .content(discoverLooksCache)
            return
        }
        guard let token = tokenProvider() else {
            looksDiscoveryStateStorage = .error(DomainError.unauthenticated.userMessage)
            return
        }

        looksDiscoveryStateStorage = .loading
        do {
            let items = try await repository.fetchDiscoverOutfits(token: token, limit: discoveryLimit)
            discoverLooksCache = items
            looksDiscoveryStateStorage = items.isEmpty ? .empty : .content(items)
        } catch {
            looksDiscoveryStateStorage = .error(error.userMessage)
        }
    }

    private func loadGarments(force: Bool) async {
        if !force, !discoverGarmentsCache.isEmpty {
            garmentsDiscoveryStateStorage = .content(discoverGarmentsCache)
            return
        }
        guard let token = tokenProvider() else {
            garmentsDiscoveryStateStorage = .error(DomainError.unauthenticated.userMessage)
            return
        }

        garmentsDiscoveryStateStorage = .loading
        do {
            let items = try await repository.fetchDiscoverGarments(token: token, limit: discoveryLimit)
            discoverGarmentsCache = items
            garmentsDiscoveryStateStorage = items.isEmpty ? .empty : .content(items)
        } catch {
            garmentsDiscoveryStateStorage = .error(error.userMessage)
        }
    }

    private func loadPeople(force: Bool) async {
        if !force, !discoverPeopleCache.isEmpty {
            peopleDiscoveryStateStorage = .content(discoverPeopleCache)
            return
        }
        guard let token = tokenProvider() else {
            peopleDiscoveryStateStorage = .error(DomainError.unauthenticated.userMessage)
            return
        }

        peopleDiscoveryStateStorage = .loading
        do {
            let items = try await repository.fetchDiscoverUsers(token: token, limit: discoveryLimit)
            discoverPeopleCache = items
            peopleDiscoveryStateStorage = items.isEmpty ? .empty : .content(items)
        } catch {
            peopleDiscoveryStateStorage = .error(error.userMessage)
        }
    }

    private func resolvedState<Item: Sendable & Equatable>(
        discoveryState: ExploreFeedState<Item>,
        searchItems: (ExploreSearchResults) -> [Item]
    ) -> ExploreFeedState<Item> {
        guard shouldUseBackendSearch else { return discoveryState }

        switch searchState {
        case .idle, .loading:
            return .loading
        case let .error(message):
            return .error(message)
        case .empty:
            return .empty
        case let .content(results):
            let items = searchItems(results)
            return items.isEmpty ? .empty : .content(items)
        }
    }

    private func replaceOutfitItem(_ updated: ExploreOutfitItem) {
        discoverLooksCache = discoverLooksCache.map { $0.id == updated.id ? updated : $0 }
        if case .content = looksDiscoveryStateStorage {
            looksDiscoveryStateStorage = discoverLooksCache.isEmpty ? .empty : .content(discoverLooksCache)
        }

        if case let .content(results) = searchState {
            let updatedResults = ExploreSearchResults(
                outfits: results.outfits.map { $0.id == updated.id ? updated : $0 },
                garments: results.garments,
                users: results.users
            )
            searchState = updatedResults.isEmpty ? .empty : .content(updatedResults)
        }
    }

    private func replaceUserItem(_ updated: ExploreUserItem) {
        discoverPeopleCache = discoverPeopleCache.map { $0.id == updated.id ? updated : $0 }
        if case .content = peopleDiscoveryStateStorage {
            peopleDiscoveryStateStorage = discoverPeopleCache.isEmpty ? .empty : .content(discoverPeopleCache)
        }

        if case let .content(results) = searchState {
            let updatedResults = ExploreSearchResults(
                outfits: results.outfits,
                garments: results.garments,
                users: results.users.map { $0.id == updated.id ? updated : $0 }
            )
            searchState = updatedResults.isEmpty ? .empty : .content(updatedResults)
        }
    }

    private func isIdle<Item>(_ state: ExploreFeedState<Item>) -> Bool where Item: Sendable & Equatable {
        if case .idle = state { return true }
        return false
    }
}
