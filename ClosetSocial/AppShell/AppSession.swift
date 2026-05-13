import Foundation
import Observation

@MainActor
@Observable
public final class AppSession {
    public private(set) var session: AuthSession?

    public init(session: AuthSession? = nil) {
        self.session = session
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
    }

    public func signOut() {
        self.session = nil
    }
}
