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
}
