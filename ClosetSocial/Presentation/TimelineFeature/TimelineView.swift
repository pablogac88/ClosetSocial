import SwiftUI

public struct TimelineView: View {
    @Bindable private var viewModel: TimelineViewModel
    private let makePublicProfileViewModel: (UUID) -> PublicProfileViewModel
    private let onAddGarmentTap: (@MainActor () -> Void)?
    @State private var isPresentingCreateSheet = false
    @State private var postForComments: FeedPost? = nil
    @State private var selectedAuthor: User? = nil
    @State private var outfitDetailPost: FeedPost? = nil
    @State private var garmentDetail: Garment? = nil

    public init(
        viewModel: TimelineViewModel,
        makePublicProfileViewModel: @escaping (UUID) -> PublicProfileViewModel,
        onAddGarmentTap: (@MainActor () -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.makePublicProfileViewModel = makePublicProfileViewModel
        self.onAddGarmentTap = onAddGarmentTap
    }

    public var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            case let .content(items):
                content(items)
            case .empty:
                EmptyStateView(
                    icon: "sparkles",
                    title: "Tu feed está vacío",
                    message: "Sigue a personas desde Explore para ver su contenido aquí. También puedes añadir prendas y outfits propios.",
                    action: onAddGarmentTap.map { .init(label: "Añadir prenda", handler: $0) }
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingCreateSheet = true
                } label: {
                    Label("Publicar", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingCreateSheet) {
            CreatePostSheet(viewModel: viewModel)
        }
        .sheet(item: $postForComments) { post in
            CommentsSheet(post: post, viewModel: viewModel)
        }
        .sheet(item: $selectedAuthor) { author in
            NavigationStack {
                PublicProfileView(viewModel: makePublicProfileViewModel(author.id))
            }
        }
        .sheet(item: $garmentDetail) { garment in
            NavigationStack {
                GarmentDetailView(garment: garment, relatedOutfits: [])
            }
        }
        .sheet(item: $outfitDetailPost) { post in
            NavigationStack {
                OutfitDetailView(
                    context: .feedPost(post),
                    onLikeTap: { Task { await viewModel.toggleLike(for: post) } },
                    onCommentTap: {
                        outfitDetailPost = nil
                        postForComments = post
                    }
                )
            }
        }
        .task { await viewModel.load() }
    }

    private func content(_ items: [FeedPost]) -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(items) { post in
                    FeedPostCard(
                        post: post,
                        onAuthorTap: { selectedAuthor = post.author },
                        onLikeTap: { Task { await viewModel.toggleLike(for: post) } },
                        onCommentTap: { postForComments = post },
                        onOutfitTap: post.outfit != nil ? { outfitDetailPost = post } : nil,
                        onGarmentTap: post.garment != nil ? { garmentDetail = post.garment } : nil
                    )
                }
            }
            .padding(20)
        }
        .refreshable { await viewModel.load() }
    }
}

// MARK: - Create Post Sheet

private struct CreatePostSheet: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: TimelineViewModel

    @State private var caption = ""
    @State private var contentKind: PostContentKind = .none
    @State private var selectedGarmentID: UUID? = nil
    @State private var selectedOutfitID: UUID? = nil

    private enum PostContentKind: String, CaseIterable {
        case none = "Ninguno"
        case garment = "Prenda"
        case outfit = "Outfit"
    }

    private var canPublish: Bool {
        !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !viewModel.isCreatingPost
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Publicación") {
                    TextField("¿Qué quieres compartir?", text: $caption, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Contenido") {
                    Picker("Tipo", selection: $contentKind) {
                        ForEach(PostContentKind.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: contentKind) {
                        selectedGarmentID = nil
                        selectedOutfitID = nil
                    }
                }

                if contentKind == .garment {
                    Section("Elige una prenda") {
                        if viewModel.availableGarments.isEmpty {
                            Text("No tienes prendas en tu armario.")
                                .foregroundStyle(.secondary)
                                .font(DSFont.footnote)
                        } else {
                            ForEach(viewModel.availableGarments) { garment in
                                SelectionRow(
                                    title: garment.name,
                                    subtitle: garment.type.name,
                                    isSelected: selectedGarmentID == garment.id
                                ) { selectedGarmentID = garment.id }
                            }
                        }
                    }
                }

                if contentKind == .outfit {
                    Section("Elige un outfit") {
                        if viewModel.availableOutfits.isEmpty {
                            Text("No tienes outfits creados.")
                                .foregroundStyle(.secondary)
                                .font(DSFont.footnote)
                        } else {
                            ForEach(viewModel.availableOutfits) { outfit in
                                SelectionRow(
                                    title: outfit.title ?? "Outfit sin título",
                                    subtitle: outfit.garments.map(\.name).joined(separator: " · "),
                                    isSelected: selectedOutfitID == outfit.id
                                ) { selectedOutfitID = outfit.id }
                            }
                        }
                    }
                }

                if let error = viewModel.createPostError {
                    Section {
                        Text(error)
                            .font(DSFont.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Publicar")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .disabled(viewModel.isCreatingPost)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isCreatingPost {
                        ProgressView()
                    } else {
                        Button("Publicar") {
                            Task {
                                await viewModel.createPost(
                                    caption: caption,
                                    outfitID: selectedOutfitID,
                                    garmentID: selectedGarmentID
                                )
                                if viewModel.createPostError == nil {
                                    dismiss()
                                }
                            }
                        }
                        .disabled(!canPublish)
                    }
                }
            }
            .task { await viewModel.loadAvailableContent() }
        }
    }
}

// MARK: - Selection Row

private struct SelectionRow: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).foregroundStyle(.primary)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(DSFont.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? DSColor.highlightSoft : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Feed Post Card

private struct FeedPostCard: View {
    let post: FeedPost
    let onAuthorTap: () -> Void
    let onLikeTap: () -> Void
    let onCommentTap: () -> Void
    var onOutfitTap: (() -> Void)? = nil
    var onGarmentTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Author
            authorRow
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, post.caption.isEmpty ? 12 : 10)

            // Caption
            if !post.caption.isEmpty {
                Text(post.caption)
                    .font(DSFont.body)
                    .foregroundStyle(DSColor.primaryText)
                    .padding(.horizontal, 16)
                    .padding(.bottom, hasMedia ? 12 : 0)
            }

            // Media — edge-to-edge
            mediaSection

            // Actions
            actionsRow
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DSColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 3)
    }

    // MARK: Author row

    private var authorRow: some View {
        Button(action: onAuthorTap) {
            HStack(spacing: 12) {
                AvatarBubble(displayName: post.author.displayName, avatarURL: post.author.avatarURL)

                VStack(alignment: .leading, spacing: 3) {
                    Text(post.author.displayName)
                        .font(DSFont.headline)
                        .foregroundStyle(DSColor.primaryText)

                    HStack(spacing: 4) {
                        Text("@\(post.author.username)")
                            .font(DSFont.footnote)
                            .foregroundStyle(DSColor.secondaryText)

                        Text("·")
                            .font(DSFont.footnote)
                            .foregroundStyle(DSColor.tertiaryText)

                        Text(post.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(DSFont.footnote)
                            .foregroundStyle(DSColor.tertiaryText)

                        if !post.isReal {
                            Image(systemName: "sparkles")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(DSColor.tertiaryText)
                        }
                    }
                }

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Media

    private var hasMedia: Bool { post.outfit != nil || post.garment != nil }

    @ViewBuilder
    private var mediaSection: some View {
        if let outfit = post.outfit {
            let canvas = OutfitCanvasView(
                layout: outfit.layout,
                garments: outfit.garments,
                cornerRadius: 0,
                backgroundColor: DSColor.background
            )
            .aspectRatio(3 / 4, contentMode: .fit)

            if let onOutfitTap {
                Button(action: onOutfitTap) { canvas }
                    .buttonStyle(.plain)
            } else {
                canvas
            }
        } else if let garment = post.garment {
            let image = GarmentImage(url: garment.imageURL)
                .aspectRatio(1, contentMode: .fit)

            if let onGarmentTap {
                Button(action: onGarmentTap) { image }
                    .buttonStyle(.plain)
            } else {
                image
            }
        }
    }

    // MARK: Actions

    private var actionsRow: some View {
        HStack(spacing: 20) {
            Button(action: onLikeTap) {
                HStack(spacing: 6) {
                    Image(systemName: post.isLikedByCurrentUser ? "heart.fill" : "heart")
                        .font(.system(size: 15, weight: .medium))
                        .symbolEffect(.bounce, value: post.isLikedByCurrentUser)
                        .foregroundStyle(
                            post.isLikedByCurrentUser
                                ? DSColor.destructive
                                : Color.secondary
                        )
                    Text("\(post.likesCount)")
                        .font(DSFont.footnote)
                        .foregroundStyle(
                            post.isLikedByCurrentUser
                                ? DSColor.destructive
                                : Color.secondary
                        )
                }
            }
            .buttonStyle(.plain)
            .disabled(!post.isReal)

            Button(action: onCommentTap) {
                HStack(spacing: 6) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.secondary)
                    Text("\(post.commentsCount)")
                        .font(DSFont.footnote)
                        .foregroundStyle(Color.secondary)
                }
            }
            .buttonStyle(.plain)
            .disabled(!post.isReal)

            Spacer()
        }
    }
}

// MARK: - Comments Sheet

private struct CommentsSheet: View {
    let post: FeedPost
    let viewModel: TimelineViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var draftText = ""

    private var canSubmit: Bool {
        !draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !viewModel.isCreatingComment
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.commentsState {
                case .idle, .loading:
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                case let .content(items):
                    commentList(items)
                case .empty:
                    VStack {
                        ContentUnavailableView(
                            "Sin comentarios",
                            systemImage: "bubble.right",
                            description: Text("Sé el primero en comentar.")
                        )
                        Spacer()
                        inputBar
                    }
                case let .error(message):
                    ContentUnavailableView(
                        "Algo ha fallado",
                        systemImage: "exclamationmark.triangle",
                        description: Text(message)
                    )
                }
            }
            .navigationTitle("Comentarios")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .task { await viewModel.loadComments(for: post) }
        }
    }

    private func commentList(_ items: [Comment]) -> some View {
        VStack(spacing: 0) {
            List(items) { comment in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(comment.author.displayName).font(DSFont.footnoteBold)
                        Text("@\(comment.author.username)")
                            .font(DSFont.footnote)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(comment.createdAt.formatted(date: .omitted, time: .shortened))
                            .font(DSFont.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(comment.text).font(DSFont.body)
                }
                .padding(.vertical, 4)
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)

            inputBar
        }
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
            if let error = viewModel.createCommentError {
                Text(error)
                    .font(DSFont.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }
            HStack(spacing: 12) {
                TextField("Añade un comentario…", text: $draftText, axis: .vertical)
                    .font(DSFont.body)
                    .lineLimit(1...4)
                    .padding(.vertical, 10)
                    .disabled(viewModel.isCreatingComment)

                if viewModel.isCreatingComment {
                    ProgressView()
                } else {
                    Button {
                        let text = draftText
                        draftText = ""
                        Task { await viewModel.createComment(for: post, text: text) }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(canSubmit ? DSColor.highlight : .secondary)
                    }
                    .disabled(!canSubmit)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .background(.regularMaterial)
    }
}

// MARK: - FeedPostKind helpers

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
