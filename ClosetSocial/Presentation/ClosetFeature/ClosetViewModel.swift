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

    private let repository: any ClosetRepository
    private let addGarmentUseCase: any AddGarmentUseCase
    private let tokenProvider: TokenProvider
    private let onGarmentAdded: OnGarmentAdded
    private let onGarmentDeleted: OnGarmentDeleted?

    public init(
        repository: any ClosetRepository,
        addGarmentUseCase: any AddGarmentUseCase,
        tokenProvider: @escaping TokenProvider,
        onGarmentAdded: @escaping OnGarmentAdded,
        onGarmentDeleted: (OnGarmentDeleted)? = nil
    ) {
        self.repository = repository
        self.addGarmentUseCase = addGarmentUseCase
        self.tokenProvider = tokenProvider
        self.onGarmentAdded = onGarmentAdded
        self.onGarmentDeleted = onGarmentDeleted
    }

    public func load() async {
        guard let token = tokenProvider() else {
            state = .error(DomainError.unauthenticated.userMessage)
            return
        }
        state = .loading
        do {
            let garments = try await repository.fetchCloset(token: token)
            state = garments.isEmpty ? .empty : .content(garments)
        } catch {
            state = .error(error.userMessage)
        }
    }

    public func makeAddGarmentViewModel() -> AddGarmentViewModel {
        AddGarmentViewModel(
            useCase: addGarmentUseCase,
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

    private func removeGarment(id: UUID) {
        guard case let .content(items) = state else { return }
        let updated = items.filter { $0.id != id }
        state = updated.isEmpty ? .empty : .content(updated)
    }
}
