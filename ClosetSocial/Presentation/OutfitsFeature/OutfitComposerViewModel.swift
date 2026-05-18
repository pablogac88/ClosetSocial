import Foundation
import Observation

@MainActor
@Observable
public final class OutfitComposerViewModel: Identifiable {
    public let id = UUID()

    public typealias TokenProvider = @MainActor () -> String?
    public typealias OnOutfitSaved = @MainActor (Outfit) -> Void

    // MARK: State

    public private(set) var wardrobeGarments: [Garment]         = []
    public private(set) var selectedGarments: [Garment]         = []
    public private(set) var currentLayout: OutfitComposerLayout?
    public private(set) var isLoadingWardrobe                   = false
    public private(set) var isSaving                            = false
    public private(set) var isPublishing                        = false
    public var saveError: String?
    public var publishError: String?
    public private(set) var savedOutfit: Outfit?
    public var coverImageUpload = ImageUploadManager()

    static let maxGarments = 6

    // MARK: Dependencies

    private let closetRepository: any ClosetRepository
    private let outfitsRepository: any OutfitsRepository
    private let timelineRepository: any TimelineRepository
    private let uploadRepository: any UploadRepository
    private let tokenProvider: TokenProvider
    private let onOutfitSaved: OnOutfitSaved?

    public init(
        closetRepository: any ClosetRepository,
        outfitsRepository: any OutfitsRepository,
        timelineRepository: any TimelineRepository,
        uploadRepository: any UploadRepository,
        tokenProvider: @escaping TokenProvider,
        onOutfitSaved: (OnOutfitSaved)? = nil
    ) {
        self.closetRepository   = closetRepository
        self.outfitsRepository  = outfitsRepository
        self.timelineRepository = timelineRepository
        self.uploadRepository   = uploadRepository
        self.tokenProvider      = tokenProvider
        self.onOutfitSaved      = onOutfitSaved
    }

    // MARK: Cover image

    public func handleCoverImagePicked(_ data: Data) async {
        guard let token = tokenProvider() else { return }
        await coverImageUpload.pick(data, using: uploadRepository, token: token)
    }

    public func retryCoverImageUpload() async {
        guard let token = tokenProvider() else { return }
        await coverImageUpload.retry(using: uploadRepository, token: token)
    }

    public func removeCoverImage() {
        coverImageUpload.remove()
    }

    // MARK: Wardrobe

    public func loadWardrobe() async {
        guard let token = tokenProvider() else { return }
        isLoadingWardrobe = true
        wardrobeGarments  = (try? await closetRepository.fetchCloset(token: token)) ?? []
        isLoadingWardrobe = false
    }

    // MARK: Selection

    public func addGarment(_ garment: Garment) {
        guard selectedGarments.count < Self.maxGarments,
              !selectedGarments.contains(where: { $0.id == garment.id }) else { return }
        selectedGarments.append(garment)
        regenerateLayout()
    }

    public func removeGarment(_ garment: Garment) {
        selectedGarments.removeAll { $0.id == garment.id }
        regenerateLayout()
    }

    public func isSelected(_ garment: Garment) -> Bool {
        selectedGarments.contains(where: { $0.id == garment.id })
    }

    public var isAtLimit: Bool { selectedGarments.count >= Self.maxGarments }

    // MARK: Layout

    private func regenerateLayout() {
        guard !selectedGarments.isEmpty else { currentLayout = nil; return }
        currentLayout = OutfitLayoutEngine.generateLayout(for: selectedGarments)
    }

    // MARK: Save (private, no post)

    public func saveOutfit(title: String?, note: String?) async {
        guard let token = tokenProvider() else {
            saveError = DomainError.unauthenticated.userMessage; return
        }
        guard !selectedGarments.isEmpty else {
            saveError = "Selecciona al menos una prenda."; return
        }
        isSaving  = true
        saveError = nil
        defer { isSaving = false }

        do {
            let outfit = try await outfitsRepository.createOutfit(
                token: token,
                request: outfitRequest(title: title, note: note)
            )
            onOutfitSaved?(outfit)
            savedOutfit = outfit
        } catch {
            saveError = error.userMessage
        }
    }

    // MARK: Publish (outfit + post)

    public func publishOutfit(title: String?, note: String?, caption: String) async {
        guard let token = tokenProvider() else {
            publishError = DomainError.unauthenticated.userMessage; return
        }
        guard !selectedGarments.isEmpty else {
            publishError = "Selecciona al menos una prenda."; return
        }
        isPublishing  = true
        publishError  = nil
        defer { isPublishing = false }

        // Step 1 — create outfit
        let outfit: Outfit
        do {
            outfit = try await outfitsRepository.createOutfit(
                token: token,
                request: outfitRequest(title: title, note: note)
            )
        } catch {
            publishError = error.userMessage
            return
        }

        // Step 2 — create post (outfit already persisted; no rollback in MVP)
        do {
            _ = try await timelineRepository.createPost(
                token: token,
                request: CreatePostRequest(
                    caption: caption,
                    outfitID: outfit.id,
                    garmentID: nil,
                    imageURLs: []
                )
            )
        } catch {
            publishError = "Look guardado, pero el post no se publicó. Inténtalo de nuevo."
            return
        }

        // Both succeeded — notify parent and signal dismiss
        onOutfitSaved?(outfit)
        savedOutfit = outfit
    }

    // MARK: Helpers

    private func outfitRequest(title: String?, note: String?) -> CreateOutfitRequest {
        CreateOutfitRequest(
            title: title,
            note: note,
            garmentIDs: selectedGarments.map(\.id),
            layout: currentLayout,
            coverImageURL: coverImageUpload.remoteURL?.absoluteString
        )
    }
}
