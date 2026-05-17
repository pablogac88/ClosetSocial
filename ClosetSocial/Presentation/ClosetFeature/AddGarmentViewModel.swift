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
    public var selectedCategory: GarmentCategory?
    public private(set) var availableCategories: [GarmentCategory] = []
    public private(set) var availableBrands: [Brand] = []
    public var color = ""
    public var errorMessage: String?
    public var catalogLoadError: String?

    public var imageUpload = ImageUploadManager()

    public private(set) var isLoadingCatalog = false
    public private(set) var isSaving = false

    private let useCase: any AddGarmentUseCase
    private let catalogRepository: any CatalogRepository
    private let uploadRepository: any UploadRepository
    private let tokenProvider: TokenProvider
    private let onSaved: OnSaved

    public init(
        useCase: any AddGarmentUseCase,
        catalogRepository: any CatalogRepository,
        uploadRepository: any UploadRepository,
        tokenProvider: @escaping TokenProvider,
        onSaved: @escaping OnSaved
    ) {
        self.useCase = useCase
        self.catalogRepository = catalogRepository
        self.uploadRepository = uploadRepository
        self.tokenProvider = tokenProvider
        self.onSaved = onSaved
    }

    public var availableTypes: [GarmentType] {
        if let cat = selectedCategory {
            return cat.subtypes
        }
        return availableCategories.flatMap(\.subtypes)
    }

    public var isLoadingTypes: Bool { isLoadingCatalog }
    public var typeLoadError: String? { catalogLoadError }

    public var isSaveDisabled: Bool {
        isSaving || imageUpload.isUploading || isLoadingCatalog || availableCategories.isEmpty || name.isEmpty || color.isEmpty
    }

    public func loadGarmentTypesIfNeeded() async {
        guard availableCategories.isEmpty, !isLoadingCatalog else { return }
        await loadCatalog()
    }

    public func loadGarmentTypes() async {
        await loadCatalog()
    }

    private func loadCatalog() async {
        guard let token = tokenProvider() else {
            catalogLoadError = DomainError.unauthenticated.userMessage
            availableCategories = GarmentCategory.defaultCategories
            return
        }

        isLoadingCatalog = true
        catalogLoadError = nil
        defer { isLoadingCatalog = false }

        async let categoriesResult = catalogRepository.fetchGarmentCategories(token: token)
        async let brandsResult = catalogRepository.fetchBrands(token: token)

        do {
            let (categories, brands) = try await (categoriesResult, brandsResult)
            availableCategories = categories.isEmpty ? GarmentCategory.defaultCategories : categories
            availableBrands = brands
        } catch {
            availableCategories = GarmentCategory.defaultCategories
            availableBrands = []
            catalogLoadError = error.userMessage
        }

        if !availableTypes.contains(type) {
            type = availableTypes.first ?? .shirt
        }
    }

    public func handleImagePicked(_ data: Data) async {
        guard let token = tokenProvider() else {
            errorMessage = DomainError.unauthenticated.userMessage
            return
        }
        await imageUpload.pick(data, using: uploadRepository, token: token)
    }

    public func retryImageUpload() async {
        guard let token = tokenProvider() else { return }
        await imageUpload.retry(using: uploadRepository, token: token)
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
            imageURL: imageUpload.remoteURL
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
