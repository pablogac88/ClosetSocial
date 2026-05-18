import Foundation
import Observation

public enum ClosetState: Sendable {
    case idle
    case loading
    case content([Garment])
    case empty
    case error(String)
}

@MainActor
@Observable
public final class ClosetViewModel {
    public typealias TokenProvider = @MainActor () -> String?
    public typealias OnGarmentAdded = @MainActor (AddGarmentResult) -> Void
    public typealias OnGarmentDeleted = @MainActor () -> Void

    public private(set) var state: ClosetState = .idle
    public private(set) var deletingGarmentIDs: Set<UUID> = []
    public private(set) var categories: [GarmentCategory] = []

    private let repository: any ClosetRepository
    private let catalogRepository: any CatalogRepository
    private let addGarmentUseCase: any AddGarmentUseCase
    private let uploadRepository: any UploadRepository
    private let tokenProvider: TokenProvider
    private let onGarmentAdded: OnGarmentAdded
    private let onGarmentDeleted: OnGarmentDeleted?

    public init(
        repository: any ClosetRepository,
        catalogRepository: any CatalogRepository,
        addGarmentUseCase: any AddGarmentUseCase,
        uploadRepository: any UploadRepository,
        tokenProvider: @escaping TokenProvider,
        onGarmentAdded: @escaping OnGarmentAdded,
        onGarmentDeleted: (OnGarmentDeleted)? = nil
    ) {
        self.repository = repository
        self.catalogRepository = catalogRepository
        self.addGarmentUseCase = addGarmentUseCase
        self.uploadRepository = uploadRepository
        self.tokenProvider = tokenProvider
        self.onGarmentAdded = onGarmentAdded
        self.onGarmentDeleted = onGarmentDeleted
    }

    public func load(showLoadingState: Bool = true) async {
        let previousState = state
        guard let token = tokenProvider() else {
            state = .error(DomainError.unauthenticated.userMessage)
            return
        }
        if showLoadingState {
            state = .loading
        }
        do {
            let garments = try await repository.fetchCloset(token: token)
            state = garments.isEmpty ? .empty : .content(garments)
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

    public func refresh() async {
        await load(showLoadingState: false)
    }

    public func makeAddGarmentViewModel() -> AddGarmentViewModel {
        AddGarmentViewModel(
            useCase: addGarmentUseCase,
            catalogRepository: catalogRepository,
            uploadRepository: uploadRepository,
            tokenProvider: tokenProvider
        ) { [weak self] result in
            guard let self else { return }
            self.appendGarment(result.garment)
            self.onGarmentAdded(result)
        }
    }

    private func appendGarment(_ garment: Garment) {
        switch state {
        case let .content(items):
            state = .content([garment] + items)
        default:
            state = .content([garment])
        }
    }

    public func delete(_ garment: Garment) async throws {
        guard let token = tokenProvider() else {
            throw DomainError.unauthenticated
        }
        guard deletingGarmentIDs.insert(garment.id).inserted else { return }
        defer { deletingGarmentIDs.remove(garment.id) }

        try await repository.deleteGarment(token: token, id: garment.id)
        removeGarment(id: garment.id)
        onGarmentDeleted?()
    }

    public func isDeleting(_ garment: Garment) -> Bool {
        deletingGarmentIDs.contains(garment.id)
    }

    public func loadCategories() async {
        guard let token = tokenProvider() else { return }
        categories = (try? await catalogRepository.fetchGarmentCategories(token: token)) ?? []
    }

    private func removeGarment(id: UUID) {
        guard case let .content(items) = state else { return }
        let updated = items.filter { $0.id != id }
        state = updated.isEmpty ? .empty : .content(updated)
    }
}
