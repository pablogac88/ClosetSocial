import SwiftUI

public struct ProfileView: View {
    @Bindable private var viewModel: ProfileViewModel
    private let makePublicProfileViewModel: (UUID) -> PublicProfileViewModel

    @State private var followListTarget: FollowListKind?

    public init(
        viewModel: ProfileViewModel,
        makePublicProfileViewModel: @escaping (UUID) -> PublicProfileViewModel
    ) {
        self.viewModel = viewModel
        self.makePublicProfileViewModel = makePublicProfileViewModel
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
            ToolbarItem(placement: .topBarTrailing) {
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
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
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
        .background(Color(red: 0.975, green: 0.970, blue: 0.962).ignoresSafeArea())
    }

    // MARK: Header

    private func profileHeader(_ profile: UserProfile) -> some View {
        VStack(spacing: 20) {
            AvatarBubble(
                displayName: profile.user.displayName,
                size: 96,
                fillColor: Color(red: 0.91, green: 0.87, blue: 0.82),
                textColor: Color(red: 0.44, green: 0.38, blue: 0.32)
            )

            VStack(spacing: 5) {
                Text(profile.user.displayName)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.14, green: 0.11, blue: 0.09))

                Text("@\(profile.user.username)")
                    .font(.system(.subheadline, design: .rounded, weight: .regular))
                    .foregroundStyle(Color(red: 0.56, green: 0.50, blue: 0.46))

                if let bio = profile.user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.system(.body, design: .rounded, weight: .regular))
                        .foregroundStyle(Color(red: 0.40, green: 0.35, blue: 0.31))
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
            .background(Color.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
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
                                    ? Color(red: 0.14, green: 0.11, blue: 0.09)
                                    : Color(red: 0.58, green: 0.52, blue: 0.48)
                            )
                            .animation(.none, value: viewModel.selectedTab)

                        Rectangle()
                            .frame(height: 2)
                            .foregroundStyle(
                                viewModel.selectedTab == tab
                                    ? Color(red: 0.25, green: 0.30, blue: 0.58)
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
        .background(Color(red: 0.975, green: 0.970, blue: 0.962))
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
                                .foregroundStyle(Color(red: 0.28, green: 0.24, blue: 0.22))
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
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
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
                .foregroundStyle(Color(red: 0.14, green: 0.11, blue: 0.09))
            Text(label)
                .font(.system(.caption, design: .rounded, weight: .regular))
                .foregroundStyle(Color(red: 0.58, green: 0.52, blue: 0.48))
        }
        .frame(maxWidth: .infinity)
    }
}
