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

    public private(set) var state: ClosetState = .idle

    private let repository: any ClosetRepository
    private let addGarmentUseCase: any AddGarmentUseCase
    private let tokenProvider: TokenProvider
    private let onGarmentAdded: OnGarmentAdded

    public init(
        repository: any ClosetRepository,
        addGarmentUseCase: any AddGarmentUseCase,
        tokenProvider: @escaping TokenProvider,
        onGarmentAdded: @escaping OnGarmentAdded
    ) {
        self.repository = repository
        self.addGarmentUseCase = addGarmentUseCase
        self.tokenProvider = tokenProvider
        self.onGarmentAdded = onGarmentAdded
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
}
