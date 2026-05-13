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
        VStack(spacing: 12) {
            AvatarBubble(
                displayName: profile.user.displayName,
                size: 88,
                fillColor: DSColor.accentDeepSoft,
                textColor: DSColor.accentDeep
            )

            Text(profile.user.displayName).font(DSFont.title)
            Text("@\(profile.user.username)")
                .font(DSFont.headline)
                .foregroundStyle(.secondary)

            if let bio = profile.user.bio, !bio.isEmpty {
                Text(bio)
                    .font(DSFont.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 20)

        HStack(spacing: 12) {
            MetricCard(title: "Posts", value: "\(profile.postsCount)")
            MetricCard(title: "Prendas", value: "\(profile.closetCount)")
            MetricCard(title: "Outfits", value: "\(profile.outfitCount)")
        }

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
