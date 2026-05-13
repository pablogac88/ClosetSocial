import Foundation

/// Crear una prenda implica varios efectos secundarios:
///  - persistir en backend
///  - refrescar timeline (aparece la compra)
///  - refrescar profile (sube el contador)
///
/// Encapsulamos esa orquestación aquí para que el ViewModel quede simple.
public struct AddGarmentResult: Sendable, Equatable {
    public let garment: Garment
    public let updatedTimeline: [FeedPost]
    public let updatedProfile: UserProfile

    public init(garment: Garment, updatedTimeline: [FeedPost], updatedProfile: UserProfile) {
        self.garment = garment
        self.updatedTimeline = updatedTimeline
        self.updatedProfile = updatedProfile
    }
}

public protocol AddGarmentUseCase: Sendable {
    func callAsFunction(token: String, garment: NewGarment) async throws -> AddGarmentResult
}

public struct DefaultAddGarmentUseCase: AddGarmentUseCase {
    private let closetRepository: any ClosetRepository
    private let timelineRepository: any TimelineRepository
    private let profileRepository: any ProfileRepository

    public init(
        closetRepository: any ClosetRepository,
        timelineRepository: any TimelineRepository,
        profileRepository: any ProfileRepository
    ) {
        self.closetRepository = closetRepository
        self.timelineRepository = timelineRepository
        self.profileRepository = profileRepository
    }

    public func callAsFunction(token: String, garment: NewGarment) async throws -> AddGarmentResult {
        let created = try await closetRepository.createGarment(token: token, garment: garment)

        async let timelineTask = timelineRepository.fetchTimeline(token: token)
        async let profileTask = profileRepository.fetchProfile(token: token)

        let timeline = try await timelineTask
        let profile = try await profileTask

        return AddGarmentResult(
            garment: created,
            updatedTimeline: timeline,
            updatedProfile: profile
        )
    }
}
