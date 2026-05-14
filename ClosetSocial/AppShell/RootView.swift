import SwiftUI

public struct RootView: View {
    @Bindable private var session: AppSession
    private let dependencies: AppDependencies
    @State private var unauthScreen: UnauthScreen = .welcome

    public init(session: AppSession, dependencies: AppDependencies) {
        self.session = session
        self.dependencies = dependencies
    }

    public var body: some View {
        ZStack {
            BackgroundGradientView()

            if session.isAuthenticated {
                MainTabView(session: session, dependencies: dependencies)
                    .id(session.currentToken)
                    .transition(.opacity)
            } else {
                switch unauthScreen {
                case .welcome:
                    WelcomeView(
                        onGetStarted: { unauthScreen = .auth(.register) },
                        onLogin: { unauthScreen = .auth(.login) }
                    )
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                case .auth(let mode):
                    LoginView(
                        viewModel: makeLoginViewModel(mode: mode),
                        onBack: { unauthScreen = .welcome }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.88), value: session.isAuthenticated)
        .animation(.spring(response: 0.42, dampingFraction: 0.85), value: unauthScreen)
        .onChange(of: session.isAuthenticated) { _, isAuthenticated in
            if !isAuthenticated { unauthScreen = .welcome }
        }
    }

    private func makeLoginViewModel(mode: AuthMode) -> LoginViewModel {
        LoginViewModel(
            useCase: dependencies.authenticateUseCase,
            initialMode: mode,
            prefilledEmail: "pablo@closetsocial.app",
            prefilledPassword: "password123"
        ) { [session] authSession in
            session.signIn(authSession)
        }
    }
}

// MARK: - Unauth navigation state

private enum UnauthScreen: Equatable {
    case welcome
    case auth(AuthMode)
}
