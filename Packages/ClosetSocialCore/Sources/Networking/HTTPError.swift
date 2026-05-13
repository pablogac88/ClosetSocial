import Foundation

/// Errores tipados de la capa de red. No contienen texto localizado de UI.
public enum HTTPError: Error, Sendable, Hashable {
    case invalidResponse
    case decoding
    case server(status: Int, message: String?)
    case offline
    case unknown
}
