import SwiftUI

public struct ProfileView: View {
    @Bindable private var viewModel: ProfileViewModel
    private let makePublicProfileViewModel: (UUID) -> PublicProfileViewModel
    private let uploadRepository: any UploadRepository
    private let tokenProvider: @MainActor () -> String?

    @State private var followListTarget: FollowListKind?
    @State private var isEditingProfile = false
    @State private var isShowingNotifications = false

    public init(
        viewModel: ProfileViewModel,
        makePublicProfileViewModel: @escaping (UUID) -> PublicProfileViewModel,
        uploadRepository: any UploadRepository,
        tokenProvider: @escaping @MainActor () -> String?
    ) {
        self.viewModel = viewModel
        self.makePublicProfileViewModel = makePublicProfileViewModel
        self.uploadRepository = uploadRepository
        self.tokenProvider = tokenProvider
    }

    public var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            case let .content(profile):
                profileContent(profile)
            case let .error(message):
                ContentUnavailableView(
                    "No hemos podido cargar tu perfil",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if case .content = viewModel.state {
                    Button {
                        isEditingProfile = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(DSColor.primaryText)
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 4) {
                    Button {
                        isShowingNotifications = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(DSColor.primaryText)
                            if viewModel.notificationsViewModel.unreadCount > 0 {
                                Circle()
                                    .fill(DSColor.destructive)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 4, y: -4)
                            }
                        }
                    }

                    Menu {
                        Button(role: .destructive) {
                            viewModel.logout()
                        } label: {
                            Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
        }
        .task {
            async let profile: Void = viewModel.load()
            async let notifications: Void = viewModel.notificationsViewModel.load()
            _ = await (profile, notifications)
        }
        .refreshable { await viewModel.load() }
        .sheet(isPresented: $isEditingProfile) {
            if case let .content(profile) = viewModel.state {
                EditProfileSheet(
                    initialDisplayName: profile.user.displayName,
                    initialBio: profile.user.bio ?? "",
                    initialAvatarURL: profile.user.avatarURL?.absoluteString ?? "",
                    uploadRepository: uploadRepository,
                    tokenProvider: tokenProvider,
                    onSave: { displayName, bio, avatarURL in
                        let saved = await viewModel.updateProfile(
                            displayName: displayName,
                            bio: bio.isEmpty ? nil : bio,
                            avatarURL: avatarURL.isEmpty ? nil : avatarURL
                        )
                        return saved
                    }
                )
            }
        }
        .navigationDestination(isPresented: $isShowingNotifications) {
            NotificationsView(viewModel: viewModel.notificationsViewModel)
        }
        .sheet(item: $followListTarget) { kind in
            if case let .content(profile) = viewModel.state {
                FollowListSheet(
                    userID: profile.user.id,
                    kind: kind,
                    currentUserID: profile.user.id,
                    repository: viewModel.repository,
                    tokenProvider: { [viewModel] in viewModel.currentToken }
                )
            }
        }
    }

    // MARK: Body

    private func profileContent(_ profile: UserProfile) -> some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                profileHeader(profile)

                Section {
                    tabContent
                } header: {
                    tabBar
                }
            }
        }
        .background(DSColor.background.ignoresSafeArea())
    }

    // MARK: Header

    private func profileHeader(_ profile: UserProfile) -> some View {
        VStack(spacing: 20) {
            AvatarBubble(
                displayName: profile.user.displayName,
                avatarURL: profile.user.avatarURL,
                size: 96,
                fillColor: DSColor.warmFill,
                textColor: DSColor.secondaryText
            )

            VStack(spacing: 5) {
                Text(profile.user.displayName)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(DSColor.primaryText)

                Text("@\(profile.user.username)")
                    .font(.system(.subheadline, design: .rounded, weight: .regular))
                    .foregroundStyle(DSColor.secondaryText)

                if let bio = profile.user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.system(.body, design: .rounded, weight: .regular))
                        .foregroundStyle(DSColor.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                }
            }

            HStack(spacing: 0) {
                ProfileStat(value: profile.closetCount,  label: "Prendas")
                Divider().frame(height: 28)
                ProfileStat(value: profile.outfitCount,  label: "Outfits")
                Divider().frame(height: 28)
                Button { followListTarget = .followers } label: {
                    ProfileStat(value: profile.followerCount, label: "Seguidores")
                }
                .buttonStyle(.plain)
                Divider().frame(height: 28)
                Button { followListTarget = .following } label: {
                    ProfileStat(value: profile.followingCount, label: "Siguiendo")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(DSColor.surface.opacity(0.65), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 24)
    }

    // MARK: Tab bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(ProfileTab.allCases, id: \.self) { tab in
                Button {
                    Task { await viewModel.selectTab(tab) }
                } label: {
                    VStack(spacing: 8) {
                        Text(tab.title)
                            .font(.system(
                                .subheadline,
                                design: .rounded,
                                weight: viewModel.selectedTab == tab ? .semibold : .regular
                            ))
                            .foregroundStyle(
                                viewModel.selectedTab == tab
                                    ? DSColor.primaryText
                                    : DSColor.secondaryText
                            )
                            .animation(.none, value: viewModel.selectedTab)

                        Rectangle()
                            .frame(height: 2)
                            .foregroundStyle(
                                viewModel.selectedTab == tab
                                    ? DSColor.highlight
                                    : Color.clear
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .background(DSColor.background)
        .overlay(alignment: .bottom) { Divider() }
    }

    // MARK: Tab content

    @ViewBuilder
    private var tabContent: some View {
        switch viewModel.selectedTab {
        case .posts:
            PostsTabContent(state: viewModel.postsState)
        case .outfits:
            OutfitsTabContent(state: viewModel.outfitsState)
        case .garments:
            GarmentsTabContent(state: viewModel.garmentsState)
        }
    }
}

// MARK: - Posts tab

private struct PostsTabContent: View {
    let state: ProfileTabState<[FeedPost]>

    var body: some View {
        switch state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, 60)

        case let .content(posts):
            LazyVStack(spacing: 14) {
                ForEach(posts) { post in
                    ProfilePostCard(post: post)
                }
            }
            .padding(16)

        case .empty:
            EmptyStateView(
                icon: "doc.text",
                title: "Aún sin posts",
                message: "Tus publicaciones aparecerán aquí cuando las compartas."
            )
            .frame(minHeight: 320)

        case let .error(message):
            ContentUnavailableView(
                "No hemos podido cargar tus posts",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
            .padding(.top, 20)
        }
    }
}

// MARK: - Outfits tab

private struct OutfitsTabContent: View {
    let state: ProfileTabState<[Outfit]>

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        switch state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, 60)

        case let .content(outfits):
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(outfits) { outfit in
                    VStack(alignment: .leading, spacing: 8) {
                        OutfitCanvasView(
                            layout: outfit.layout,
                            garments: outfit.garments,
                            cornerRadius: 16
                        )
                        .aspectRatio(3 / 4, contentMode: .fit)
                        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 3)

                        if let title = outfit.title {
                            Text(title)
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundStyle(DSColor.primaryText)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(16)

        case .empty:
            EmptyStateView(
                icon: "square.grid.2x2",
                title: "Sin looks todavía",
                message: "Crea tu primer outfit y aparecerá aquí."
            )
            .frame(minHeight: 320)

        case let .error(message):
            ContentUnavailableView(
                "No hemos podido cargar tus outfits",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
            .padding(.top, 20)
        }
    }
}

// MARK: - Garments tab

private struct GarmentsTabContent: View {
    let state: ProfileTabState<[Garment]>

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        switch state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, 60)

        case let .content(garments):
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(garments) { garment in
                    GarmentImage(url: garment.imageURL)
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
                }
            }
            .padding(16)

        case .empty:
            EmptyStateView(
                icon: "hanger",
                title: "Tu armario está vacío",
                message: "Añade prendas desde la pestaña Armario."
            )
            .frame(minHeight: 320)

        case let .error(message):
            ContentUnavailableView(
                "No hemos podido cargar tu armario",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
            .padding(.top, 20)
        }
    }
}

// MARK: - Profile post card

private struct ProfilePostCard: View {
    let post: FeedPost

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !post.caption.isEmpty {
                Text(post.caption)
                    .font(DSFont.body)
                    .foregroundStyle(DSColor.secondaryText)
            }

            if let outfit = post.outfit {
                let label = "Outfit: \(outfit.title ?? outfit.garments.map(\.name).joined(separator: " · "))"
                Text(label)
                    .font(DSFont.footnoteBold)
                    .foregroundStyle(DSColor.highlight)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(DSColor.pillBackground, in: Capsule())
            } else if let garment = post.garment {
                Text("Prenda: \(garment.name)")
                    .font(DSFont.footnoteBold)
                    .foregroundStyle(DSColor.highlight)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(DSColor.pillBackground, in: Capsule())
            }

            HStack {
                Label("\(post.likesCount)", systemImage: "heart")
                    .font(DSFont.footnote)
                    .foregroundStyle(.secondary)
                Label("\(post.commentsCount)", systemImage: "bubble.right")
                    .font(DSFont.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(post.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(DSFont.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DSColor.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

// MARK: - Profile stat

private struct ProfileStat: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Text("\(value)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(DSColor.primaryText)
            Text(label)
                .font(.system(.caption, design: .rounded, weight: .regular))
                .foregroundStyle(DSColor.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}
