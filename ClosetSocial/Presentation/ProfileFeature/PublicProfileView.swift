import SwiftUI

public struct PublicProfileView: View {
    @State private var viewModel: PublicProfileViewModel

    @State private var followListTarget: FollowListKind?

    public init(viewModel: PublicProfileViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                switch viewModel.state {
                case .idle, .loading:
                    ProgressView().padding(.top, 60)
                case let .content(profile):
                    profileContent(profile)
                case let .error(message):
                    ContentUnavailableView(
                        "No hemos podido cargar este perfil",
                        systemImage: "exclamationmark.triangle",
                        description: Text(message)
                    )
                    .padding(.top, 40)
                }
            }
            .padding(20)
        }
        .navigationTitle("Perfil")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .sheet(item: $followListTarget) { kind in
            if case let .content(profile) = viewModel.state {
                FollowListSheet(
                    userID: profile.user.id,
                    kind: kind,
                    currentUserID: viewModel.currentUserID,
                    repository: viewModel.repository,
                    tokenProvider: { [viewModel] in viewModel.currentToken }
                )
            }
        }
    }

    @ViewBuilder
    private func profileContent(_ profile: PublicUserProfile) -> some View {
        // Header
        VStack(spacing: 12) {
            AvatarBubble(
                displayName: profile.user.displayName,
                avatarURL: profile.user.avatarURL,
                size: 88,
                fillColor: DSColor.warmFill,
                textColor: DSColor.secondaryText
            )

            VStack(spacing: 5) {
                Text(profile.user.displayName)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
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

            if !viewModel.isOwnProfile {
                followButton(profile)
            }
        }
        .padding(.top, 20)

        // Stats
        HStack(spacing: 0) {
            PublicStat(value: profile.closetCount,   label: "Prendas")
            Divider().frame(height: 28)
            PublicStat(value: profile.outfitCount,   label: "Outfits")
            Divider().frame(height: 28)
            Button { followListTarget = .followers } label: {
                PublicStat(value: profile.followerCount, label: "Seguidores")
            }
            .buttonStyle(.plain)
            Divider().frame(height: 28)
            Button { followListTarget = .following } label: {
                PublicStat(value: profile.followingCount, label: "Siguiendo")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(DSColor.surface.opacity(0.65), in: RoundedRectangle(cornerRadius: 20, style: .continuous))

        // Follow error
        if let error = viewModel.followError {
            Text(error)
                .font(.system(.footnote, design: .rounded, weight: .medium))
                .foregroundStyle(DSColor.destructive)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
        }

        // Posts
        if !profile.posts.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Posts recientes")
                    .font(DSFont.headline)
                    .padding(.top, 4)

                ForEach(profile.posts) { post in
                    PublicPostRow(post: post)
                }
            }
        }
    }

    private func followButton(_ profile: PublicUserProfile) -> some View {
        Button {
            Task { await viewModel.toggleFollow() }
        } label: {
            Group {
                if viewModel.isFollowLoading {
                    ProgressView()
                        .tint(profile.isFollowing ? DSColor.secondaryText : .white)
                } else {
                    Text(profile.isFollowing ? "Siguiendo" : "Seguir")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                }
            }
            .frame(width: 120, height: 38)
            .background(
                profile.isFollowing
                    ? Color.white
                    : Color(red: 0.10, green: 0.08, blue: 0.07),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .foregroundStyle(
                profile.isFollowing
                    ? DSColor.primaryText
                    : Color.white
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        profile.isFollowing
                            ? DSColor.border
                            : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isFollowLoading)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: profile.isFollowing)
    }
}

// MARK: - Stat

private struct PublicStat: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Text("\(value)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(DSColor.primaryText)
            Text(label)
                .font(.system(.caption, design: .rounded, weight: .regular))
                .foregroundStyle(DSColor.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Public Post Row

private struct PublicPostRow: View {
    let post: FeedPost

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(post.caption)
                .font(DSFont.body)
                .foregroundStyle(DSColor.secondaryText)

            if let outfit = post.outfit {
                Text("Outfit: \(outfit.title ?? outfit.garments.map(\.name).joined(separator: " · "))")
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
