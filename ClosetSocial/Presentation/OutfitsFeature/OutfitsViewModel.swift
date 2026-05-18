import Foundation
import Observation

public enum OutfitsState: Sendable {
    case idle
    case loading
    case content([Outfit])
    case empty
    case error(String)
}

public enum OutfitsTab: String, CaseIterable, Sendable {
    case myOutfits = "Tus looks"
    case saved     = "Guardados"
}

@MainActor
@Observable
public final class OutfitsViewModel {
    public typealias TokenProvider = @MainActor () -> String?
    public typealias OnOutfitDeleted = @MainActor () -> Void

    public var selectedTab: OutfitsTab = .myOutfits
    public private(set) var myOutfitsState: OutfitsState = .idle
    public private(set) var savedState: OutfitsState = .idle
    public private(set) var availableGarments: [Garment] = []
    public private(set) var isSaving = false
    public private(set) var deletingOutfitIDs: Set<UUID> = []
    public var saveError: String?

    public var activeState: OutfitsState {
        selectedTab == .myOutfits ? myOutfitsState : savedState
    }

    // Legacy accessor kept for backward compatibility.
    public var state: OutfitsState {
        get { myOutfitsState }
        set { myOutfitsState = newValue }
    }

    private let repository: any OutfitsRepository
    private let closetRepository: any ClosetRepository
    private let timelineRepository: any TimelineRepository
    private let uploadRepository: any UploadRepository
    private let tokenProvider: TokenProvider
    private let onOutfitDeleted: OnOutfitDeleted?

    public init(
        repository: any OutfitsRepository,
        closetRepository: any ClosetRepository,
        timelineRepository: any TimelineRepository,
        uploadRepository: any UploadRepository,
        tokenProvider: @escaping TokenProvider,
        onOutfitDeleted: (OnOutfitDeleted)? = nil
    ) {
        self.repository = repository
        self.closetRepository = closetRepository
        self.timelineRepository = timelineRepository
        self.uploadRepository = uploadRepository
        self.tokenProvider = tokenProvider
        self.onOutfitDeleted = onOutfitDeleted
    }

    public func load() async {
        await loadMyOutfits()
    }

    public func loadMyOutfits(silent: Bool = false) async {
        guard let token = tokenProvider() else {
            if !silent { myOutfitsState = .error(DomainError.unauthenticated.userMessage) }
            return
        }
        if !silent { myOutfitsState = .loading }
        do {
            let outfits = try await repository.fetchOutfits(token: token)
            myOutfitsState = outfits.isEmpty ? .empty : .content(outfits)
        } catch {
            if !silent { myOutfitsState = .error(error.userMessage) }
        }
    }

    public func loadSaved(silent: Bool = false) async {
        guard let token = tokenProvider() else {
            if !silent { savedState = .error(DomainError.unauthenticated.userMessage) }
            return
        }
        if !silent { savedState = .loading }
        do {
            let outfits = try await repository.fetchSavedOutfits(token: token)
            savedState = outfits.isEmpty ? .empty : .content(outfits)
        } catch {
            if !silent { savedState = .error(error.userMessage) }
        }
    }

    public func loadActiveTab() async {
        switch selectedTab {
        case .myOutfits: await loadMyOutfits(silent: true)
        case .saved:     await loadSaved(silent: true)
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
            timelineRepository: timelineRepository,
            uploadRepository: uploadRepository,
            tokenProvider: tokenProvider,
            onOutfitSaved: { [weak self] outfit in self?.appendOutfit(outfit) }
        )
    }

    public func appendOutfit(_ outfit: Outfit) {
        switch myOutfitsState {
        case let .content(items): myOutfitsState = .content([outfit] + items)
        default:                  myOutfitsState = .content([outfit])
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
            switch myOutfitsState {
            case let .content(items): myOutfitsState = .content([outfit] + items)
            default:                  myOutfitsState = .content([outfit])
            }
        } catch {
            saveError = error.userMessage
        }
    }

    public func delete(_ outfit: Outfit) async throws {
        guard let token = tokenProvider() else { throw DomainError.unauthenticated }
        guard deletingOutfitIDs.insert(outfit.id).inserted else { return }
        defer { deletingOutfitIDs.remove(outfit.id) }

        try await repository.deleteOutfit(token: token, id: outfit.id)
        removeOutfit(id: outfit.id, from: .myOutfits)
        onOutfitDeleted?()
    }

    public func unsave(_ outfit: Outfit) async {
        guard let token = tokenProvider() else { return }
        removeOutfit(id: outfit.id, from: .saved)
        do {
            try await repository.unsaveOutfit(token: token, id: outfit.id)
        } catch {
            // Rollback: re-insert at beginning
            switch savedState {
            case let .content(items): savedState = .content([outfit] + items)
            default: savedState = .content([outfit])
            }
        }
    }

    public func isDeleting(_ outfit: Outfit) -> Bool {
        deletingOutfitIDs.contains(outfit.id)
    }

    private func removeOutfit(id: UUID, from tab: OutfitsTab) {
        switch tab {
        case .myOutfits:
            guard case let .content(items) = myOutfitsState else { return }
            let updated = items.filter { $0.id != id }
            myOutfitsState = updated.isEmpty ? .empty : .content(updated)
        case .saved:
            guard case let .content(items) = savedState else { return }
            let updated = items.filter { $0.id != id }
            savedState = updated.isEmpty ? .empty : .content(updated)
        }
    }
}
