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
    public var errorMessage: String?

    // Upload state
    public var pickedImageData: Data?
    public var uploadedImageURL: URL?
    public private(set) var isUploading = false
    public var uploadError: String?

    public private(set) var isSaving = false

    private let useCase: any AddGarmentUseCase
    private let uploadRepository: any UploadRepository
    private let tokenProvider: TokenProvider
    private let onSaved: OnSaved

    public init(
        useCase: any AddGarmentUseCase,
        uploadRepository: any UploadRepository,
        tokenProvider: @escaping TokenProvider,
        onSaved: @escaping OnSaved
    ) {
        self.useCase = useCase
        self.uploadRepository = uploadRepository
        self.tokenProvider = tokenProvider
        self.onSaved = onSaved
    }

    public var isSaveDisabled: Bool {
        isSaving || isUploading || name.isEmpty || color.isEmpty
    }

    public func handleImagePicked(_ data: Data) async {
        guard let token = tokenProvider() else {
            uploadError = DomainError.unauthenticated.userMessage
            return
        }
        isUploading = true
        uploadError = nil
        defer { isUploading = false }

        let mimeType = mimeType(for: data)
        do {
            let url = try await uploadRepository.uploadImage(data, mimeType: mimeType, token: token)
            uploadedImageURL = url
            pickedImageData = data
        } catch {
            uploadError = error.userMessage
            pickedImageData = nil
            uploadedImageURL = nil
        }
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
            imageURL: uploadedImageURL
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

    private func mimeType(for data: Data) -> String {
        let bytes = Array(data.prefix(4))
        if bytes.starts(with: [0xFF, 0xD8, 0xFF]) { return "image/jpeg" }
        if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return "image/png" }
        if bytes.count >= 4, bytes[0] == 0x52, bytes[1] == 0x49, bytes[2] == 0x46, bytes[3] == 0x46 {
            return "image/webp"
        }
        return "image/jpeg"
    }
}

private extension String {
    var trimmedToNil: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
