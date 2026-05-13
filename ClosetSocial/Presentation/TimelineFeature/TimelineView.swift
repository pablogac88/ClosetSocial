import SwiftUI

public struct TimelineView: View {
    @Bindable private var viewModel: TimelineViewModel

    public init(viewModel: TimelineViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            case let .content(items):
                content(items)
            case .empty:
                ContentUnavailableView(
                    "Tu timeline está vacío",
                    systemImage: "sparkles",
                    description: Text("Cuando tus amigos compartan compras u outfits aparecerán aquí.")
                )
            case let .error(message):
                ContentUnavailableView(
                    "Algo ha fallado",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
        .navigationTitle("Timeline")
        .toolbarTitleDisplayMode(.large)
        .task { await viewModel.load() }
    }

    private func content(_ items: [FeedPost]) -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(items) { post in
                    FeedPostCard(post: post)
                }
            }
            .padding(20)
        }
        .refreshable { await viewModel.load() }
    }
}

private struct FeedPostCard: View {
    let post: FeedPost

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                AvatarBubble(displayName: post.author.displayName)

                VStack(alignment: .leading, spacing: 3) {
                    Text(post.author.displayName).font(DSFont.headline)
                    Text("@\(post.author.username) · \(post.kind.title)")
                        .font(DSFont.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Text(post.caption)
                .font(DSFont.body)
                .foregroundStyle(DSColor.secondaryText)

            if let outfit = post.outfit {
                Text("Outfit: \(outfit.title ?? outfit.garments.map(\.name).joined(separator: " · "))")
                    .font(DSFont.footnoteBold)
                    .foregroundStyle(DSColor.highlight)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(DSColor.pillBackground, in: Capsule())
            } else if let garment = post.garment {
                Text("Prenda destacada: \(garment.name)")
                    .font(DSFont.footnoteBold)
                    .foregroundStyle(DSColor.highlight)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(DSColor.pillBackground, in: Capsule())
            }

            Text(post.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(DSFont.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}

extension FeedPostKind {
    var title: String {
        switch self {
        case .outfit: "Outfit"
        case .garment: "Prenda"
        case .purchase: "Compra"
        case .post: "Post"
        }
    }
}
