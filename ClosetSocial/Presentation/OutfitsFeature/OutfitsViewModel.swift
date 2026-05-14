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
    public private(set) var availableGarments: [Garment] = []
    public private(set) var isSaving = false
    public var saveError: String?

    private let repository: any OutfitsRepository
    private let closetRepository: any ClosetRepository
    private let tokenProvider: TokenProvider

    public init(
        repository: any OutfitsRepository,
        closetRepository: any ClosetRepository,
        tokenProvider: @escaping TokenProvider
    ) {
        self.repository = repository
        self.closetRepository = closetRepository
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

    public func loadAvailableGarments() async {
        guard let token = tokenProvider() else { return }
        availableGarments = (try? await closetRepository.fetchCloset(token: token)) ?? []
    }

    // MARK: Composer factory

    public func makeComposerViewModel() -> OutfitComposerViewModel {
        OutfitComposerViewModel(
            closetRepository: closetRepository,
            outfitsRepository: repository,
            tokenProvider: tokenProvider,
            onOutfitSaved: { [weak self] outfit in self?.appendOutfit(outfit) }
        )
    }

    public func appendOutfit(_ outfit: Outfit) {
        switch state {
        case let .content(items): state = .content([outfit] + items)
        default:                  state = .content([outfit])
        }
    }

    public func create(title: String?, note: String?, garments: [Garment]) async {
        guard let token = tokenProvider() else {
            saveError = DomainError.unauthenticated.userMessage
            return
        }
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        let request = CreateOutfitRequest(
            title: title,
            note: note,
            garmentIDs: garments.map(\.id)
        )
        do {
            let outfit = try await repository.createOutfit(token: token, request: request)
            switch state {
            case let .content(items):
                state = .content([outfit] + items)
            default:
                state = .content([outfit])
            }
        } catch {
            saveError = error.userMessage
        }
    }
}
