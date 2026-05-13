import Foundation
import Observation

public enum OutfitsState: Sendable {
    case idle
    case loading
    case content([Outfit])
    case empty
    case error(String)
}

@MainActor
@Observable
public final class OutfitsViewModel {
    public typealias TokenProvider = @MainActor () -> String?

    public private(set) var state: OutfitsState = .idle

    private let repository: any OutfitsRepository
    private let tokenProvider: TokenProvider

    public init(
        repository: any OutfitsRepository,
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
            let outfits = try await repository.fetchOutfits(token: token)
            state = outfits.isEmpty ? .empty : .content(outfits)
        } catch {
            state = .error(error.userMessage)
        }
    }

    /// Outfits locales (creación todavía no persiste en backend).
    public func appendLocal(title: String?, note: String?, garments: [Garment]) {
        let outfit = Outfit(
            id: UUID(),
            title: title,
            note: note,
            garments: garments,
            createdAt: .now
        )
        switch state {
        case let .content(items):
            state = .content([outfit] + items)
        default:
            state = .content([outfit])
        }
    }
}
