import SwiftUI

public struct ProfileView: View {
    @Bindable private var viewModel: ProfileViewModel

    public init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
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
                        "No hemos podido cargar tu perfil",
                        systemImage: "exclamationmark.triangle",
                        description: Text(message)
                    )
                    .padding(.top, 40)
                }

                Button(role: .destructive) {
                    viewModel.logout()
                } label: {
                    Text("Cerrar sesión")
                        .font(DSFont.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .padding(.top, 8)
            }
            .padding(20)
        }
        .navigationTitle("Perfil")
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    @ViewBuilder
    private func profileContent(_ profile: UserProfile) -> some View {
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
        }
        .padding(.top, 20)

        HStack(spacing: 12) {
            MetricCard(title: "Posts", value: "\(profile.postsCount)")
            MetricCard(title: "Prendas", value: "\(profile.closetCount)")
            MetricCard(title: "Outfits", value: "\(profile.outfitCount)")
        }
    }
}
