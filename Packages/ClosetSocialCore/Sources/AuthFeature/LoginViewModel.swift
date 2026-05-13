import Foundation
import Observation
import Domain
import DesignSystem

public enum AuthMode: String, CaseIterable, Identifiable, Sendable {
    case login
    case register

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .login: "Entrar"
        case .register: "Registrarse"
        }
    }
}

@MainActor
@Observable
public final class LoginViewModel {
    public typealias OnAuthenticated = @MainActor (AuthSession) -> Void

    public var mode: AuthMode = .login
    public var username = ""
    public var displayName = ""
    public var email = ""
    public var password = ""
    public var errorMessage: String?
    public private(set) var isSubmitting = false

    private let useCase: any AuthenticateUserUseCase
    private let onAuthenticated: OnAuthenticated

    public init(
        useCase: any AuthenticateUserUseCase,
        prefilledEmail: String = "",
        prefilledPassword: String = "",
        onAuthenticated: @escaping OnAuthenticated
    ) {
        self.useCase = useCase
        self.email = prefilledEmail
        self.password = prefilledPassword
        self.onAuthenticated = onAuthenticated
    }

    public var isSubmitDisabled: Bool {
        if isSubmitting { return true }
        if email.isEmpty || password.isEmpty { return true }
        if mode == .register, (username.isEmpty || displayName.isEmpty) { return true }
        return false
    }

    public var submitTitle: String {
        mode == .login ? "Entrar" : "Crear cuenta"
    }

    public func submit() async {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let session: AuthSession
            switch mode {
            case .login:
                session = try await useCase.login(email: email, password: password)
            case .register:
                session = try await useCase.register(
                    username: username,
                    displayName: displayName,
                    email: email,
                    password: password
                )
            }
            password = ""
            username = ""
            displayName = ""
            onAuthenticated(session)
        } catch {
            errorMessage = error.userMessage
        }
    }
}
