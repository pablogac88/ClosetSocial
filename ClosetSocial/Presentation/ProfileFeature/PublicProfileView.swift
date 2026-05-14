import SwiftUI

public struct PublicProfileView: View {
    @State private var viewModel: PublicProfileViewModel

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
    }

    @ViewBuilder
    private func profileContent(_ profile: PublicUserProfile) -> some View {
        // Header
        VStack(spacing: 12) {
            AvatarBubble(
                displayName: profile.user.displayName,
                size: 88,
                fillColor: Color(red: 0.91, green: 0.87, blue: 0.82),
                textColor: Color(red: 0.44, green: 0.38, blue: 0.32)
            )

            VStack(spacing: 5) {
                Text(profile.user.displayName)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
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

            followButton(profile)
        }
        .padding(.top, 20)

        // Stats
        HStack(spacing: 0) {
            PublicStat(value: profile.postsCount,    label: "Posts")
            Divider().frame(height: 28)
            PublicStat(value: profile.followerCount, label: "Seguidores")
            Divider().frame(height: 28)
            PublicStat(value: profile.followingCount, label: "Siguiendo")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 20, style: .continuous))

        // Follow error
        if let error = viewModel.followError {
            Text(error)
                .font(.system(.footnote, design: .rounded, weight: .medium))
                .foregroundStyle(Color(red: 0.72, green: 0.18, blue: 0.18))
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
                        .tint(profile.isFollowing ? Color(red: 0.40, green: 0.35, blue: 0.31) : .white)
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
                    ? Color(red: 0.14, green: 0.11, blue: 0.09)
                    : Color.white
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        profile.isFollowing
                            ? Color(red: 0.80, green: 0.76, blue: 0.72)
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
                .foregroundStyle(Color(red: 0.14, green: 0.11, blue: 0.09))
            Text(label)
                .font(.system(.caption, design: .rounded, weight: .regular))
                .foregroundStyle(Color(red: 0.58, green: 0.52, blue: 0.48))
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
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
