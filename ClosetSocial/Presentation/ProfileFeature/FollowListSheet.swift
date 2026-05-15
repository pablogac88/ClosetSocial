import SwiftUI

public enum FollowListKind: String, Identifiable, Sendable {
    case followers
    case following

    public var id: String { rawValue }

    var title: String {
        switch self {
        case .followers: "Seguidores"
        case .following: "Siguiendo"
        }
    }
}

public struct FollowListSheet: View {
    public typealias TokenProvider = @MainActor () -> String?

    let userID: UUID
    let kind: FollowListKind
    let currentUserID: UUID?
    let repository: any ProfileRepository
    let tokenProvider: TokenProvider

    @State private var users: [User] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedUserID: UUID?

    public init(
        userID: UUID,
        kind: FollowListKind,
        currentUserID: UUID?,
        repository: any ProfileRepository,
        tokenProvider: @escaping TokenProvider
    ) {
        self.userID = userID
        self.kind = kind
        self.currentUserID = currentUserID
        self.repository = repository
        self.tokenProvider = tokenProvider
    }

    public var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    ContentUnavailableView(
                        "No se pudo cargar la lista",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else if users.isEmpty {
                    EmptyStateView(
                        icon: "person.2",
                        title: kind == .followers ? "Sin seguidores aún" : "No sigue a nadie aún",
                        message: kind == .followers
                            ? "Cuando alguien siga este perfil aparecerá aquí."
                            : "Cuando este perfil siga a alguien aparecerá aquí."
                    )
                } else {
                    List(users) { user in
                        Button {
                            selectedUserID = user.id
                        } label: {
                            UserRow(user: user)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowSeparatorTint(Color(red: 0.88, green: 0.83, blue: 0.78))
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(red: 0.975, green: 0.970, blue: 0.962).ignoresSafeArea())
            .navigationDestination(item: $selectedUserID) { id in
                PublicProfileView(
                    viewModel: PublicProfileViewModel(
                        userID: id,
                        currentUserID: currentUserID,
                        repository: repository,
                        tokenProvider: tokenProvider
                    )
                )
            }
        }
        .task { await load() }
    }

    private func load() async {
        guard let token = tokenProvider() else {
            errorMessage = DomainError.unauthenticated.userMessage
            isLoading = false
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            users = try await {
                switch kind {
                case .followers: try await repository.fetchFollowers(userID: userID, token: token)
                case .following: try await repository.fetchFollowing(userID: userID, token: token)
                }
            }()
        } catch {
            errorMessage = error.userMessage
        }
        isLoading = false
    }
}

private struct UserRow: View {
    let user: User

    var body: some View {
        HStack(spacing: 14) {
            AvatarBubble(
                displayName: user.displayName,
                avatarURL: user.avatarURL,
                size: 46,
                fillColor: Color(red: 0.91, green: 0.87, blue: 0.82),
                textColor: Color(red: 0.44, green: 0.38, blue: 0.32)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(user.displayName)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color(red: 0.14, green: 0.11, blue: 0.09))
                Text("@\(user.username)")
                    .font(.system(.caption, design: .rounded, weight: .regular))
                    .foregroundStyle(Color(red: 0.56, green: 0.50, blue: 0.46))
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }
}
