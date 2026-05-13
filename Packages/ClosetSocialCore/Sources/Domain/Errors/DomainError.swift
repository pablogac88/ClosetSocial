import Foundation

/// Errores de dominio. No contienen texto localizado — la capa de UI los traduce.
public enum DomainError: Error, Sendable, Hashable {
    case invalidCredentials
    case emailAlreadyExists
    case unauthenticated
    case transport(TransportFailure)

    public enum TransportFailure: Error, Sendable, Hashable {
        case offline
        case server(message: String)
        case decoding
        case unknown
    }
}
