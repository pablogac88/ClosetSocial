import SwiftUI

public struct ExploreView: View {
    @Bindable private var viewModel: ExploreViewModel
    private let makePublicProfileViewModel: (UUID) -> PublicProfileViewModel

    @State private var selectedOutfit: Outfit?
    @State private var selectedGarment: Garment?
    @State private var selectedUserID: UUID?

    public init(
        viewModel: ExploreViewModel,
        makePublicProfileViewModel: @escaping (UUID) -> PublicProfileViewModel
    ) {
        self.viewModel = viewModel
        self.makePublicProfileViewModel = makePublicProfileViewModel
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                header
                ExploreSearchBar(text: $viewModel.searchText)
                content
            }
            .padding(.top, 20)
            .padding(.bottom, 28)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(red: 0.973, green: 0.962, blue: 0.949).ignoresSafeArea())
        .navigationDestination(item: $selectedOutfit) { outfit in
            OutfitDetailView(context: .myOutfit(outfit))
        }
        .navigationDestination(item: $selectedGarment) { garment in
            GarmentDetailView(
                garment: garment,
                relatedOutfits: viewModel.relatedOutfits(for: garment.id)
            )
        }
        .navigationDestination(item: $selectedUserID) { userID in
            PublicProfileView(viewModel: makePublicProfileViewModel(userID))
        }
        .task { await viewModel.load() }
        .task(id: viewModel.searchText) { await viewModel.handleSearchTextChanged() }
        .refreshable { await viewModel.refresh() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.shouldUseBackendSearch {
            searchContent
        } else {
            editorialContent
        }
    }

    @ViewBuilder
    private var editorialContent: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, 48)

        case .empty:
            EmptyStateView(
                icon: "sparkles.square.filled.on.square",
                title: "La comunidad acaba de empezar",
                message: "Cuando haya actividad en el timeline aparecerán looks, prendas y personas. Prueba a buscar algo mientras tanto."
            )

        case let .error(message):
            ContentUnavailableView(
                "No hemos podido cargar Explore",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )

        case .content:
            if viewModel.isShortQuery {
                ExploreHintCard(
                    icon: "text.cursor",
                    title: "Escribe al menos 2 caracteres",
                    message: "Mientras tanto te dejamos contenido real del timeline para seguir navegando."
                )
                .padding(.horizontal, 20)
            }

            if !viewModel.outfitPosts.isEmpty {
                ExploreSection(
                    title: "Looks",
                    subtitle: "Combinaciones reales que ya están compartiendo en la comunidad."
                ) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 18) {
                            ForEach(viewModel.outfitPosts) { post in
                                ExploreLookCard(post: post) {
                                    if let outfit = post.outfit {
                                        selectedOutfit = outfit
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }

            if !viewModel.garmentPosts.isEmpty {
                ExploreSection(
                    title: "Prendas",
                    subtitle: "Piezas reales que entran en el timeline a través de compras o publicaciones."
                ) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(viewModel.garmentPosts) { post in
                                ExploreEditorialGarmentCard(post: post) {
                                    if let garment = post.garment {
                                        selectedGarment = garment
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }

            if !viewModel.people.isEmpty {
                ExploreSection(
                    title: "Personas",
                    subtitle: "Usuarios reales con actividad reciente en el timeline."
                ) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(viewModel.people) { person in
                                ExploreEditorialPersonCard(person: person) {
                                    selectedUserID = person.id
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }

            if viewModel.outfitPosts.isEmpty, viewModel.garmentPosts.isEmpty, viewModel.people.isEmpty {
                EmptyStateView(
                    icon: "rectangle.on.rectangle.angled",
                    title: "Aún poco contenido",
                    message: "Cuando haya más actividad en el timeline, Explore ganará profundidad."
                )
            }
        }
    }

    @ViewBuilder
    private var searchContent: some View {
        switch viewModel.searchState {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, 48)

        case let .error(message):
            ContentUnavailableView(
                "No hemos podido buscar ahora mismo",
                systemImage: "magnifyingglass",
                description: Text(message)
            )

        case .empty:
            EmptyStateView(
                icon: "magnifyingglass",
                title: "Sin resultados",
                message: "Prueba con otro nombre, marca, color o usuario."
            )

        case .content:
            if !viewModel.searchUsers.isEmpty {
                ExploreSection(
                    title: "Usuarios",
                    subtitle: "Usuarios que coinciden con tu búsqueda."
                ) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(viewModel.searchUsers) { user in
                                ExploreSearchUserCard(user: user) {
                                    selectedUserID = user.id
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }

            if !viewModel.searchGarments.isEmpty {
                ExploreSection(
                    title: "Prendas",
                    subtitle: "Prendas que coinciden con tu búsqueda."
                ) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(viewModel.searchGarments) { garment in
                                ExploreSearchGarmentCard(garment: garment) {
                                    selectedGarment = garment
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }

            if !viewModel.searchOutfits.isEmpty {
                ExploreSection(
                    title: "Outfits",
                    subtitle: "Looks encontrados por título o nota."
                ) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 18) {
                            ForEach(viewModel.searchOutfits) { outfit in
                                ExploreSearchOutfitCard(outfit: outfit) {
                                    selectedOutfit = outfit
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Descubre")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.14, green: 0.11, blue: 0.09))
            Text(viewModel.shouldUseBackendSearch
                 ? "Resultados para tu búsqueda"
                 : "Contenido real de la comunidad")
                .font(DSFont.body)
                .foregroundStyle(Color(red: 0.52, green: 0.46, blue: 0.41))
        }
        .padding(.horizontal, 20)
    }

}

private struct ExploreSearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(red: 0.56, green: 0.48, blue: 0.41))

            TextField("Busca usuarios, prendas o outfits", text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(DSFont.body)
                .foregroundStyle(Color(red: 0.18, green: 0.15, blue: 0.13))

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(red: 0.68, green: 0.61, blue: 0.55))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 0.96, green: 0.92, blue: 0.88))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.75), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}

private struct ExploreSection<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DSFont.title)
                    .foregroundStyle(Color(red: 0.15, green: 0.12, blue: 0.10))
                Text(subtitle)
                    .font(DSFont.footnote)
                    .foregroundStyle(Color(red: 0.47, green: 0.40, blue: 0.35))
            }
            .padding(.horizontal, 20)

            content
        }
    }
}

private struct ExploreHintCard: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(red: 0.54, green: 0.46, blue: 0.39))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DSFont.footnoteBold)
                    .foregroundStyle(Color(red: 0.22, green: 0.18, blue: 0.16))
                Text(message)
                    .font(DSFont.footnote)
                    .foregroundStyle(Color(red: 0.44, green: 0.38, blue: 0.33))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.82))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.8), lineWidth: 1)
        )
    }
}

private struct ExploreLookCard: View {
    let post: FeedPost
    let onTap: () -> Void

    private var outfit: Outfit? { post.outfit }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 14) {
                OutfitCanvasView(
                    layout: outfit?.layout,
                    garments: outfit?.garments ?? [],
                    cornerRadius: 24,
                    backgroundColor: Color(red: 0.98, green: 0.96, blue: 0.93)
                )
                .aspectRatio(3 / 4, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(DSFont.headline)
                        .foregroundStyle(Color(red: 0.16, green: 0.12, blue: 0.10))
                        .lineLimit(2)

                    Text(post.author.displayName)
                        .font(DSFont.footnoteBold)
                        .foregroundStyle(Color(red: 0.49, green: 0.42, blue: 0.37))

                    if !post.caption.isEmpty {
                        Text(post.caption)
                            .font(DSFont.footnote)
                            .foregroundStyle(Color(red: 0.33, green: 0.28, blue: 0.25))
                            .lineLimit(2)
                    }
                }
            }
            .padding(16)
            .frame(width: 248, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.8), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 18, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    private var title: String {
        if let title = outfit?.title, !title.isEmpty {
            return title
        }
        return outfit?.garments.map(\.name).joined(separator: " · ") ?? "Look compartido"
    }
}

private struct ExploreEditorialGarmentCard: View {
    let post: FeedPost
    let onTap: () -> Void

    private var garment: Garment? { post.garment }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                GarmentImage(url: garment?.imageURL)
                    .frame(width: 176, height: 210)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(garment?.name ?? "Prenda")
                        .font(DSFont.headline)
                        .foregroundStyle(Color(red: 0.16, green: 0.12, blue: 0.10))
                        .lineLimit(2)

                    Text(detailLine)
                        .font(DSFont.footnote)
                        .foregroundStyle(Color(red: 0.49, green: 0.42, blue: 0.37))
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        AvatarBubble(
                            displayName: post.author.displayName,
                            avatarURL: post.author.avatarURL,
                            size: 28,
                            fillColor: Color(red: 0.93, green: 0.88, blue: 0.83),
                            textColor: Color(red: 0.46, green: 0.39, blue: 0.34)
                        )
                        Text(post.author.displayName)
                            .font(DSFont.caption)
                            .foregroundStyle(Color(red: 0.33, green: 0.28, blue: 0.25))
                            .lineLimit(1)
                    }
                }
            }
            .padding(14)
            .frame(width: 204, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Color.white.opacity(0.8), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    private var detailLine: String {
        [
            garment?.brand,
            garment?.type.rawValue,
            garment?.color
        ]
        .compactMap { value in
            guard let value else { return nil }
            return value.isEmpty ? nil : value
        }
        .joined(separator: " · ")
    }
}

private struct ExploreEditorialPersonCard: View {
    let person: ExplorePerson
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    AvatarBubble(
                        displayName: person.user.displayName,
                        avatarURL: person.user.avatarURL,
                        size: 54,
                        fillColor: Color(red: 0.93, green: 0.88, blue: 0.83),
                        textColor: Color(red: 0.46, green: 0.39, blue: 0.34)
                    )
                    Spacer()
                    Text(person.lastActivityAt.formatted(date: .abbreviated, time: .omitted))
                        .font(DSFont.caption)
                        .foregroundStyle(Color(red: 0.60, green: 0.53, blue: 0.48))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(person.user.displayName)
                        .font(DSFont.headline)
                        .foregroundStyle(Color(red: 0.16, green: 0.12, blue: 0.10))
                    Text("@\(person.user.username)")
                        .font(DSFont.footnote)
                        .foregroundStyle(Color(red: 0.49, green: 0.42, blue: 0.37))
                }

                if let bio = person.user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(DSFont.footnote)
                        .foregroundStyle(Color(red: 0.35, green: 0.30, blue: 0.26))
                        .lineLimit(2)
                } else if let spotlightCaption = person.spotlightCaption {
                    Text("“\(spotlightCaption)”")
                        .font(DSFont.footnote)
                        .italic()
                        .foregroundStyle(Color(red: 0.35, green: 0.30, blue: 0.26))
                        .lineLimit(2)
                }

                HStack(spacing: 16) {
                    PersonMetric(value: "\(person.postsCount)", label: "Posts")
                    PersonMetric(value: "\(person.looksCount)", label: "Looks")
                    PersonMetric(value: "\(person.garmentsCount)", label: "Prendas")
                }
            }
            .padding(18)
            .frame(width: 224, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.8), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 18, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }
}

private struct ExploreSearchUserCard: View {
    let user: User
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 14) {
                AvatarBubble(
                    displayName: user.displayName,
                    avatarURL: user.avatarURL,
                    size: 58,
                    fillColor: Color(red: 0.93, green: 0.88, blue: 0.83),
                    textColor: Color(red: 0.46, green: 0.39, blue: 0.34)
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName)
                        .font(DSFont.headline)
                        .foregroundStyle(Color(red: 0.16, green: 0.12, blue: 0.10))
                    Text("@\(user.username)")
                        .font(DSFont.footnote)
                        .foregroundStyle(Color(red: 0.49, green: 0.42, blue: 0.37))
                }

                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(DSFont.footnote)
                        .foregroundStyle(Color(red: 0.35, green: 0.30, blue: 0.26))
                        .lineLimit(3)
                }
            }
            .padding(18)
            .frame(width: 220, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.8), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 18, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }
}

private struct ExploreSearchGarmentCard: View {
    let garment: Garment
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                GarmentImage(url: garment.imageURL)
                    .frame(width: 176, height: 210)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(garment.name)
                        .font(DSFont.headline)
                        .foregroundStyle(Color(red: 0.16, green: 0.12, blue: 0.10))
                        .lineLimit(2)

                    Text(detailLine)
                        .font(DSFont.footnote)
                        .foregroundStyle(Color(red: 0.49, green: 0.42, blue: 0.37))
                        .lineLimit(2)
                }
            }
            .padding(14)
            .frame(width: 204, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Color.white.opacity(0.8), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    private var detailLine: String {
        [garment.brand, garment.type.rawValue, garment.color]
            .compactMap { value in
                guard let value else { return nil }
                return value.isEmpty ? nil : value
            }
            .joined(separator: " · ")
    }
}

private struct ExploreSearchOutfitCard: View {
    let outfit: Outfit
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 14) {
                OutfitCanvasView(
                    layout: outfit.layout,
                    garments: outfit.garments,
                    cornerRadius: 24,
                    backgroundColor: Color(red: 0.98, green: 0.96, blue: 0.93)
                )
                .aspectRatio(3 / 4, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(DSFont.headline)
                        .foregroundStyle(Color(red: 0.16, green: 0.12, blue: 0.10))
                        .lineLimit(2)

                    if let note = outfit.note, !note.isEmpty {
                        Text(note)
                            .font(DSFont.footnote)
                            .foregroundStyle(Color(red: 0.33, green: 0.28, blue: 0.25))
                            .lineLimit(2)
                    } else {
                        Text(outfit.garments.map(\.name).joined(separator: " · "))
                            .font(DSFont.footnote)
                            .foregroundStyle(Color(red: 0.33, green: 0.28, blue: 0.25))
                            .lineLimit(2)
                    }
                }
            }
            .padding(16)
            .frame(width: 248, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.8), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 18, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    private var title: String {
        if let title = outfit.title, !title.isEmpty {
            return title
        }
        return outfit.garments.map(\.name).joined(separator: " · ")
    }
}

private struct PersonMetric: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.17, green: 0.14, blue: 0.12))
            Text(label)
                .font(DSFont.caption)
                .foregroundStyle(Color(red: 0.55, green: 0.48, blue: 0.43))
        }
    }
}
