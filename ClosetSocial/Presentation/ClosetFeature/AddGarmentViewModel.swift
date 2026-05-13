import Foundation
import Observation

@MainActor
@Observable
public final class AddGarmentViewModel {
    public typealias TokenProvider = @MainActor () -> String?
    public typealias OnSaved = @MainActor (AddGarmentResult) -> Void

    public var name = ""
    public var brand = ""
    public var type: GarmentType = .shirt
    public var color = ""
    public var imageURL = ""
    public var errorMessage: String?
    public private(set) var isSaving = false

    private let useCase: any AddGarmentUseCase
    private let tokenProvider: TokenProvider
    private let onSaved: OnSaved

    public init(
        useCase: any AddGarmentUseCase,
        tokenProvider: @escaping TokenProvider,
        onSaved: @escaping OnSaved
    ) {
        self.useCase = useCase
        self.tokenProvider = tokenProvider
        self.onSaved = onSaved
    }

    public var isSaveDisabled: Bool {
        isSaving || name.isEmpty || color.isEmpty
    }

    public func save() async -> Bool {
        guard let token = tokenProvider() else {
            errorMessage = DomainError.unauthenticated.userMessage
            return false
        }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        let new = NewGarment(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            brand: brand.trimmingCharacters(in: .whitespacesAndNewlines).trimmedToNil,
            type: type,
            color: color.trimmingCharacters(in: .whitespacesAndNewlines),
            imageURL: imageURL.trimmingCharacters(in: .whitespacesAndNewlines).trimmedToNil.flatMap(URL.init(string:))
        )

        do {
            let result = try await useCase(token: token, garment: new)
            onSaved(result)
            return true
        } catch {
            errorMessage = error.userMessage
            return false
        }
    }
}

private extension String {
    var trimmedToNil: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
