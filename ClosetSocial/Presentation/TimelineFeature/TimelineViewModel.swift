import Foundation
import Observation

public enum TimelineState: Sendable {
    case idle
    case loading
    case content([FeedPost])
    case empty
    case error(String)
}

@MainActor
@Observable
public final class TimelineViewModel {
    public typealias TokenProvider = @MainActor () -> String?

    public private(set) var state: TimelineState = .idle

    private let repository: any TimelineRepository
    private let tokenProvider: TokenProvider

    public init(
        repository: any TimelineRepository,
        tokenProvider: @escaping TokenProvider
    ) {
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
            let items = try await repository.fetchTimeline(token: token)
            state = items.isEmpty ? .empty : .content(items)
        } catch {
            state = .error(error.userMessage)
        }
    }

    /// Permite a otras features (AddGarment) refrescar el timeline tras un cambio.
    public func replace(with items: [FeedPost]) {
        state = items.isEmpty ? .empty : .content(items)
    }
}
