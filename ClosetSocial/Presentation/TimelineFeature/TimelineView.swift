import SwiftUI

public struct TimelineView: View {
    @Bindable private var viewModel: TimelineViewModel
    @State private var isPresentingCreateSheet = false
    @State private var postForComments: FeedPost? = nil

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
        .task { await viewModel.load() }
    }

    private func content(_ items: [FeedPost]) -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(items) { post in
                    FeedPostCard(
                        post: post,
                        onLikeTap: { Task { await viewModel.toggleLike(for: post) } },
                        onCommentTap: { postForComments = post }
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
                                    subtitle: garment.type.rawValue,
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
    let onLikeTap: () -> Void
    let onCommentTap: () -> Void

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

            HStack(spacing: 20) {
                Button(action: onLikeTap) {
                    Label("\(post.likesCount)", systemImage: post.isLikedByCurrentUser ? "heart.fill" : "heart")
                        .font(DSFont.footnote)
                        .foregroundStyle(post.isLikedByCurrentUser ? .red : .secondary)
                }
                .buttonStyle(.plain)
                .disabled(!post.isReal)

                Button(action: onCommentTap) {
                    Label("\(post.commentsCount)", systemImage: "bubble.right")
                        .font(DSFont.footnote)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(!post.isReal)
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
