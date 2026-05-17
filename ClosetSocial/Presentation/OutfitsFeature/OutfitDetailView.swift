import SwiftUI

// MARK: - Context

public enum OutfitDetailContext {
    case myOutfit(Outfit)
    case feedPost(FeedPost)

    var outfit: Outfit? {
        switch self {
        case .myOutfit(let o):  return o
        case .feedPost(let p):  return p.outfit
        }
    }

    var post: FeedPost? {
        if case .feedPost(let p) = self { return p }
        return nil
    }
}

// MARK: - View

public struct OutfitDetailView: View {
    let context: OutfitDetailContext
    var onLikeTap: (() -> Void)?    = nil
    var onCommentTap: (() -> Void)? = nil
    var onDelete: (() async throws -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var selectedGarment: Garment?
    @State private var isShowingDeleteConfirmation = false
    @State private var deleteErrorMessage: String?

    private var outfit: Outfit? { context.outfit }
    private var post: FeedPost? { context.post }

    public init(
        context: OutfitDetailContext,
        onLikeTap: (() -> Void)? = nil,
        onCommentTap: (() -> Void)? = nil,
        onDelete: (() async throws -> Void)? = nil
    ) {
        self.context      = context
        self.onLikeTap    = onLikeTap
        self.onCommentTap = onCommentTap
        self.onDelete = onDelete
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                hero
                infoSection
                if let outfit, !outfit.garments.isEmpty {
                    garmentsSection(outfit.garments)
                }
                if let post { actionsSection(post) }
            }
        }
        .background(DSColor.background.ignoresSafeArea())
        .sheet(item: $selectedGarment) { garment in
            NavigationStack {
                GarmentDetailView(
                    garment: garment,
                    relatedOutfits: [context.outfit].compactMap { $0 }
                        .filter { $0.garments.contains { $0.id == garment.id } }
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(outfit?.title ?? "Look")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(DSColor.primaryText.opacity(0.7))
            }
            if canDelete {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        isShowingDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .confirmationDialog(
            "Eliminar outfit",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Eliminar", role: .destructive) {
                Task { await deleteOutfit() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se eliminará este look. Las prendas seguirán en tu armario.")
        }
        .alert("No hemos podido borrar el outfit", isPresented: deleteErrorIsPresented) {
            Button("Aceptar", role: .cancel) { deleteErrorMessage = nil }
        } message: {
            Text(deleteErrorMessage ?? "")
        }
    }

    // MARK: Hero

    private var hero: some View {
        GeometryReader { geo in
            ZStack {
                DSColor.background

                if let outfit {
                    OutfitCanvasView(
                        layout: outfit.layout,
                        garments: outfit.garments,
                        cornerRadius: 0,
                        backgroundColor: .clear
                    )
                    .padding(.horizontal, heroCanvasPadding(geo.size.width))
                    .padding(.vertical, 20)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1 / 0.78, contentMode: .fit)
        .clipShape(UnevenRoundedRectangle(
            bottomLeadingRadius: 28,
            bottomTrailingRadius: 28
        ))
        .shadow(color: .black.opacity(0.08), radius: 24, x: 0, y: 10)
        .shadow(color: .black.opacity(0.03), radius: 4,  x: 0, y: 2)
    }

    // Keep canvas proportionally tall (3:4) inside the wide hero.
    private func heroCanvasPadding(_ heroWidth: CGFloat) -> CGFloat {
        let heroHeight = heroWidth * 0.78
        let canvasWidth = heroHeight * 3 / 4  // 3:4 portrait aspect
        return max((heroWidth - canvasWidth) / 2, 24)
    }

    // MARK: Info

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title + note
            VStack(alignment: .leading, spacing: 8) {
                if let title = outfit?.title {
                    Text(title)
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .foregroundStyle(DSColor.primaryText)
                }
                if let note = outfit?.note {
                    Text(note)
                        .font(.system(.body, design: .rounded, weight: .regular))
                        .foregroundStyle(DSColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Author + date (feedPost context)
            if let post {
                authorRow(post)
                if !post.caption.isEmpty {
                    Text(post.caption)
                        .font(.system(.subheadline, design: .rounded, weight: .regular))
                        .italic()
                        .foregroundStyle(DSColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else if let createdAt = outfit?.createdAt {
                Text(createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(.caption, design: .rounded, weight: .regular))
                    .foregroundStyle(DSColor.tertiaryText)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 8)
    }

    private func authorRow(_ post: FeedPost) -> some View {
        HStack(spacing: 12) {
            AvatarBubble(
                displayName: post.author.displayName,
                avatarURL: post.author.avatarURL,
                size: 40,
                fillColor: DSColor.warmFill,
                textColor: DSColor.secondaryText
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(post.author.displayName)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(DSColor.primaryText)
                Text("@\(post.author.username) · \(post.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.system(.caption, design: .rounded, weight: .regular))
                    .foregroundStyle(DSColor.secondaryText)
            }
        }
    }

    // MARK: Garments

    private func garmentsSection(_ garments: [Garment]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Prendas")
                .font(.system(.footnote, design: .rounded, weight: .semibold))
                .foregroundStyle(DSColor.secondaryText)
                .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(garments) { garment in
                        GarmentDetailCard(garment: garment) {
                            selectedGarment = garment
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .padding(.top, 28)
        .padding(.bottom, 8)
    }

    // MARK: Actions

    private func actionsSection(_ post: FeedPost) -> some View {
        HStack(spacing: 16) {
            if let onLikeTap {
                ActionPill(
                    icon: post.isLikedByCurrentUser ? "heart.fill" : "heart",
                    label: "\(post.likesCount)",
                    isActive: post.isLikedByCurrentUser,
                    activeColor: DSColor.destructive,
                    disabled: !post.isReal,
                    action: onLikeTap
                )
            }
            if let onCommentTap {
                ActionPill(
                    icon: "bubble.right",
                    label: "\(post.commentsCount)",
                    isActive: false,
                    activeColor: DSColor.accent,
                    disabled: !post.isReal,
                    action: onCommentTap
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 40)
    }
}

private extension OutfitDetailView {
    var canDelete: Bool {
        if case .myOutfit = context { return onDelete != nil }
        return false
    }

    var deleteErrorIsPresented: Binding<Bool> {
        Binding(
            get: { deleteErrorMessage != nil },
            set: { isPresented in
                if !isPresented { deleteErrorMessage = nil }
            }
        )
    }

    func deleteOutfit() async {
        guard let onDelete else { return }
        do {
            try await onDelete()
            dismiss()
        } catch {
            deleteErrorMessage = error.userMessage
        }
    }
}

// MARK: - Garment detail card

private struct GarmentDetailCard: View {
    let garment: Garment
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button { onTap?() } label: { cardContent }
            .buttonStyle(.plain)
            .disabled(onTap == nil)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            GarmentImage(url: garment.imageURL)
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 3)

            VStack(alignment: .leading, spacing: 3) {
                Text(garment.name)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(DSColor.primaryText)
                    .lineLimit(1)
                Text(garment.type.name)
                    .font(.system(.caption2, design: .rounded, weight: .regular))
                    .foregroundStyle(DSColor.tertiaryText)
                if let brand = garment.brand {
                    Text(brand)
                        .font(.system(.caption2, design: .rounded, weight: .regular))
                        .foregroundStyle(DSColor.secondaryText)
                        .lineLimit(1)
                }
            }
            .frame(width: 96, alignment: .leading)
        }
    }
}

// MARK: - Action pill

private struct ActionPill: View {
    let icon: String
    let label: String
    let isActive: Bool
    let activeColor: Color
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: isActive ? .semibold : .regular))
                Text(label)
                    .font(.system(.subheadline, design: .rounded, weight: isActive ? .semibold : .regular))
            }
            .foregroundStyle(isActive ? activeColor : DSColor.secondaryText)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                isActive
                    ? activeColor.opacity(0.10)
                    : DSColor.surfaceElevated.opacity(0.7),
                in: Capsule()
            )
            .animation(.easeInOut(duration: 0.18), value: isActive)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}
