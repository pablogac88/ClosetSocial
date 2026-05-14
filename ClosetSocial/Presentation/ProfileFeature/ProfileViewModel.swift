import Foundation
import Observation

public enum ProfileState: Sendable {
    case idle
    case loading
    case content(UserProfile)
    case error(String)
}

public enum ProfileTab: CaseIterable, Hashable, Sendable {
    case posts, outfits, garments

    var title: String {
        switch self {
        case .posts:    "Posts"
        case .outfits:  "Outfits"
        case .garments: "Prendas"
        }
    }
}

public enum ProfileTabState<T: Sendable>: Sendable {
    case idle
    case loading
    case content(T)
    case empty
    case error(String)
}

@MainActor
@Observable
public final class ProfileViewModel {
    public typealias TokenProvider = @MainActor () -> String?
    public typealias OnLogout = @MainActor () -> Void

    public private(set) var state: ProfileState = .idle
    public private(set) var selectedTab: ProfileTab = .posts
    public private(set) var postsState: ProfileTabState<[FeedPost]> = .idle
    public private(set) var outfitsState: ProfileTabState<[Outfit]> = .idle
    public private(set) var garmentsState: ProfileTabState<[Garment]> = .idle

    public let repository: any ProfileRepository
    private let timelineRepository: any TimelineRepository
    private let closetRepository: any ClosetRepository
    private let outfitsRepository: any OutfitsRepository
    private let tokenProvider: TokenProvider
    private let onLogout: OnLogout
    private var loadedTabs: Set<ProfileTab> = []

    public init(
        repository: any ProfileRepository,
        timelineRepository: any TimelineRepository,
        closetRepository: any ClosetRepository,
        outfitsRepository: any OutfitsRepository,
        tokenProvider: @escaping TokenProvider,
        onLogout: @escaping OnLogout
    ) {
        self.repository = repository
        self.timelineRepository = timelineRepository
        self.closetRepository = closetRepository
        self.outfitsRepository = outfitsRepository
        self.tokenProvider = tokenProvider
        self.onLogout = onLogout
    }

    public func load() async {
        guard let token = tokenProvider() else {
            state = .error(DomainError.unauthenticated.userMessage)
            return
        }
        state = .loading
        invalidateTabs()
        do {
            let profile = try await repository.fetchProfile(token: token)
            state = .content(profile)
            await loadTabIfNeeded(selectedTab, token: token, userID: profile.user.id)
        } catch {
            state = .error(error.userMessage)
        }
    }

    public func selectTab(_ tab: ProfileTab) async {
        selectedTab = tab
        guard case let .content(profile) = state,
              let token = tokenProvider()
        else { return }
        await loadTabIfNeeded(tab, token: token, userID: profile.user.id)
    }

    public func replace(with profile: UserProfile) {
        state = .content(profile)
        invalidateTabs()
    }

    public var currentToken: String? { tokenProvider() }

    public func logout() {
        onLogout()
    }

    // MARK: Private

    private func invalidateTabs() {
        loadedTabs = []
        postsState = .idle
        outfitsState = .idle
        garmentsState = .idle
    }

    private func loadTabIfNeeded(_ tab: ProfileTab, token: String, userID: UUID) async {
        guard !loadedTabs.contains(tab) else { return }
        loadedTabs.insert(tab)

        switch tab {
        case .posts:
            postsState = .loading
            do {
                let all = try await timelineRepository.fetchTimeline(token: token)
                let mine = all.filter { $0.author.id == userID && $0.isReal }
                postsState = mine.isEmpty ? .empty : .content(mine)
            } catch {
                loadedTabs.remove(tab)
                postsState = .error(error.userMessage)
            }

        case .outfits:
            outfitsState = .loading
            do {
                let outfits = try await outfitsRepository.fetchOutfits(token: token)
                outfitsState = outfits.isEmpty ? .empty : .content(outfits)
            } catch {
                loadedTabs.remove(tab)
                outfitsState = .error(error.userMessage)
            }

        case .garments:
            garmentsState = .loading
            do {
                let garments = try await closetRepository.fetchCloset(token: token)
                garmentsState = garments.isEmpty ? .empty : .content(garments)
            } catch {
                loadedTabs.remove(tab)
                garmentsState = .error(error.userMessage)
            }
        }
    }
}
