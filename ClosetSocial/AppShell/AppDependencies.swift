import Foundation

/// Composition root. Centraliza la creación de repositorios y use cases.
/// El target app instancia una sola vez al arrancar.
public struct AppDependencies: Sendable {
    public let authRepository: any AuthRepository
    public let timelineRepository: any TimelineRepository
    public let searchRepository: any SearchRepository
    public let closetRepository: any ClosetRepository
    public let outfitsRepository: any OutfitsRepository
    public let profileRepository: any ProfileRepository
    public let notificationRepository: any NotificationRepository
    public let authenticateUseCase: any AuthenticateUserUseCase
    public let addGarmentUseCase: any AddGarmentUseCase

    public init(
        authRepository: any AuthRepository,
        timelineRepository: any TimelineRepository,
        searchRepository: any SearchRepository,
        closetRepository: any ClosetRepository,
        outfitsRepository: any OutfitsRepository,
        profileRepository: any ProfileRepository,
        notificationRepository: any NotificationRepository
    ) {
        self.authRepository = authRepository
        self.timelineRepository = timelineRepository
        self.searchRepository = searchRepository
        self.closetRepository = closetRepository
        self.outfitsRepository = outfitsRepository
        self.profileRepository = profileRepository
        self.notificationRepository = notificationRepository

        self.authenticateUseCase = DefaultAuthenticateUserUseCase(repository: authRepository)
        self.addGarmentUseCase = DefaultAddGarmentUseCase(
            closetRepository: closetRepository,
            timelineRepository: timelineRepository,
            profileRepository: profileRepository
        )
    }

    /// Atajo para el caso típico: backend HTTP en una URL conocida.
    public static func live(baseURL: URL) -> AppDependencies {
        let client = URLSessionHTTPClient(baseURL: baseURL)
        let repos = RemoteRepositories(client: client)
        return AppDependencies(
            authRepository: repos.auth,
            timelineRepository: repos.timeline,
            searchRepository: repos.search,
            closetRepository: repos.closet,
            outfitsRepository: repos.outfits,
            profileRepository: repos.profile,
            notificationRepository: repos.notifications
        )
    }

    /// Stack en memoria — ideal para previews y tests de integración rápidos.
    public static func inMemory() -> AppDependencies {
        let backend = InMemoryClosetSocialBackend()
        return AppDependencies(
            authRepository: InMemoryAuthRepository(backend: backend),
            timelineRepository: InMemoryTimelineRepository(backend: backend),
            searchRepository: InMemorySearchRepository(backend: backend),
            closetRepository: InMemoryClosetRepository(backend: backend),
            outfitsRepository: InMemoryOutfitsRepository(backend: backend),
            profileRepository: InMemoryProfileRepository(backend: backend),
            notificationRepository: InMemoryNotificationRepository()
        )
    }
}
