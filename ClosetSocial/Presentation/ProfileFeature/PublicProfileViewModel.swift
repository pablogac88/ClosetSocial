import Foundation
import Observation

public enum PublicProfileState: Sendable {
    case idle
    case loading
    case content(PublicUserProfile)
    case error(String)
}

@MainActor
@Observable
public final class PublicProfileViewModel {
    public typealias TokenProvider = @MainActor () -> String?

    public private(set) var state: PublicProfileState = .idle
    public private(set) var isFollowLoading = false
    public private(set) var followError: String?

    private let userID: UUID
    private let repository: any ProfileRepository
    private let tokenProvider: TokenProvider

    public init(
        userID: UUID,
        repository: any ProfileRepository,
        tokenProvider: @escaping TokenProvider
    ) {
        self.userID = userID
        self.repository = repository
        self.tokenProvider = tokenProvider
    }

    public func load() async {
        guard let token = tokenProvider() else {
            state = .error(DomainError.unauthenticated.userMessage)
            return
        }
        state = .loading
        do {
            let profile = try await repository.fetchPublicProfile(userID: userID, token: token)
            state = .content(profile)
        } catch {
            state = .error(error.userMessage)
        }
    }

    public func toggleFollow() async {
        guard case let .content(profile) = state,
              let token = tokenProvider()
        else { return }

        followError = nil
        isFollowLoading = true
        defer { isFollowLoading = false }

        // Optimistic update
        let wasFollowing = profile.isFollowing
        let optimistic = PublicUserProfile(
            user: profile.user,
            closetCount: profile.closetCount,
            outfitCount: profile.outfitCount,
            postsCount: profile.postsCount,
            posts: profile.posts,
            followerCount: wasFollowing ? max(0, profile.followerCount - 1) : profile.followerCount + 1,
            followingCount: profile.followingCount,
            isFollowing: !wasFollowing
        )
        state = .content(optimistic)

        do {
            if wasFollowing {
                try await repository.unfollow(userID: userID, token: token)
            } else {
                try await repository.follow(userID: userID, token: token)
            }
        } catch {
            // Roll back optimistic update
            state = .content(profile)
            followError = error.userMessage
        }
    }
}
