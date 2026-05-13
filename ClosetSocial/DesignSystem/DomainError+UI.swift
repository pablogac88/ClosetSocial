import Foundation

public extension DomainError {
    /// Texto orientado al usuario. Vive aquí para que las features no dupliquen copys.
    var userMessage: String {
        switch self {
        case .invalidCredentials:
            return "Email o contraseña incorrectos."
        case .emailAlreadyExists:
            return "Ya existe un usuario con ese email."
        case .unauthenticated:
            return "Tu sesión ha caducado. Vuelve a entrar."
        case let .transport(failure):
            switch failure {
            case .offline:
                return "No hay conexión a internet."
            case .decoding:
                return "No hemos podido interpretar la respuesta del servidor."
            case let .server(message):
                return message
            case .unknown:
                return "Algo ha fallado. Inténtalo de nuevo."
            }
        }
    }
}

public extension Error {
    var userMessage: String {
        if let domain = self as? DomainError {
            return domain.userMessage
        }
        return localizedDescription
    }
}
