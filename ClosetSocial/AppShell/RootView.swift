import SwiftUI

public struct RootView: View {
    @Bindable private var session: AppSession
    private let dependencies: AppDependencies

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
            } else {
                LoginView(viewModel: makeLoginViewModel())
            }
        }
        .animation(.snappy, value: session.isAuthenticated)
    }

    private func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(
            useCase: dependencies.authenticateUseCase,
            prefilledEmail: "pablo@closetsocial.app",
            prefilledPassword: "password123"
        ) { [session] authSession in
            session.signIn(authSession)
        }
    }
}
