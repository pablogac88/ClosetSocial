import Foundation

/// Composition root. Centraliza la creación de repositorios y use cases.
/// El target app instancia una sola vez al arrancar.
public struct AppDependencies: Sendable {
    public let authRepository: any AuthRepository
    public let timelineRepository: any TimelineRepository
    public let searchRepository: any SearchRepository
    public let exploreRepository: any ExploreRepository
    public let closetRepository: any ClosetRepository
    public let catalogRepository: any CatalogRepository
    public let outfitsRepository: any OutfitsRepository
    public let profileRepository: any ProfileRepository
    public let notificationRepository: any NotificationRepository
    public let uploadRepository: any UploadRepository
    public let authenticateUseCase: any AuthenticateUserUseCase
    public let addGarmentUseCase: any AddGarmentUseCase

    public init(
        authRepository: any AuthRepository,
        timelineRepository: any TimelineRepository,
        searchRepository: any SearchRepository,
        exploreRepository: any ExploreRepository,
        closetRepository: any ClosetRepository,
        catalogRepository: any CatalogRepository,
        outfitsRepository: any OutfitsRepository,
        profileRepository: any ProfileRepository,
        notificationRepository: any NotificationRepository,
        uploadRepository: any UploadRepository
    ) {
        self.authRepository = authRepository
        self.timelineRepository = timelineRepository
        self.searchRepository = searchRepository
        self.exploreRepository = exploreRepository
        self.closetRepository = closetRepository
        self.catalogRepository = catalogRepository
        self.outfitsRepository = outfitsRepository
        self.profileRepository = profileRepository
        self.notificationRepository = notificationRepository
        self.uploadRepository = uploadRepository

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
        let repos = RemoteRepositories(client: client, baseURL: baseURL)
        return AppDependencies(
            authRepository: repos.auth,
            timelineRepository: repos.timeline,
            searchRepository: repos.search,
            exploreRepository: repos.explore,
            closetRepository: repos.closet,
            catalogRepository: repos.catalog,
            outfitsRepository: repos.outfits,
            profileRepository: repos.profile,
            notificationRepository: repos.notifications,
            uploadRepository: repos.upload
        )
    }

    /// Stack en memoria — ideal para previews y tests de integración rápidos.
    public static func inMemory() -> AppDependencies {
        let backend = InMemoryClosetSocialBackend()
        let closetRepository = InMemoryClosetRepository(backend: backend)
        return AppDependencies(
            authRepository: InMemoryAuthRepository(backend: backend),
            timelineRepository: InMemoryTimelineRepository(backend: backend),
            searchRepository: InMemorySearchRepository(backend: backend),
            exploreRepository: InMemoryExploreRepository(backend: backend),
            closetRepository: closetRepository,
            catalogRepository: closetRepository,
            outfitsRepository: InMemoryOutfitsRepository(backend: backend),
            profileRepository: InMemoryProfileRepository(backend: backend),
            notificationRepository: InMemoryNotificationRepository(),
            uploadRepository: InMemoryUploadRepository()
        )
    }
}
