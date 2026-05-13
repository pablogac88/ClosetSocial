import Foundation
import Observation

public enum ProfileState: Sendable {
    case idle
    case loading
    case content(UserProfile)
    case error(String)
}

@MainActor
@Observable
public final class ProfileViewModel {
    public typealias TokenProvider = @MainActor () -> String?
    public typealias OnLogout = @MainActor () -> Void

    public private(set) var state: ProfileState = .idle

    private let repository: any ProfileRepository
    private let tokenProvider: TokenProvider
    private let onLogout: OnLogout

    public init(
        repository: any ProfileRepository,
        tokenProvider: @escaping TokenProvider,
        onLogout: @escaping OnLogout
    ) {
        self.repository = repository
        self.tokenProvider = tokenProvider
        self.onLogout = onLogout
    }

    public func load() async {
        guard let token = tokenProvider() else {
            state = .error(DomainError.unauthenticated.userMessage)
            return
        }
        state = .loading
        do {
            let profile = try await repository.fetchProfile(token: token)
            state = .content(profile)
        } catch {
            state = .error(error.userMessage)
        }
    }

    public func replace(with profile: UserProfile) {
        state = .content(profile)
    }

    public func logout() {
        onLogout()
    }
}
