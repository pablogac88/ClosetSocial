import Foundation
import Observation

@MainActor
@Observable
public final class AppSession {
    public private(set) var session: AuthSession?

    public init() {
        self.session = Self.loadPersistedSession()
    }

    public var isAuthenticated: Bool {
        session != nil
    }

    public var currentToken: String? {
        session?.token
    }

    public var currentUser: User? {
        session?.user
    }

    public func signIn(_ session: AuthSession) {
        self.session = session
        Self.persist(session)
    }

    public func signOut() {
        self.session = nil
        UserDefaults.standard.removeObject(forKey: Self.key)
    }

    // MARK: - Persistence

    private nonisolated static let key = "app.closetsocial.session"

    private static func persist(_ session: AuthSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private nonisolated static func loadPersistedSession() -> AuthSession? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let session = try? JSONDecoder().decode(AuthSession.self, from: data)
        else { return nil }
        return session
    }
}
