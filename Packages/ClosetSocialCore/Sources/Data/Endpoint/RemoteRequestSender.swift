import Foundation
import Domain
import Networking

/// Pequeño helper que serializa cuerpos JSON, ejecuta la request y mapea
/// errores HTTP a `DomainError`. Mantiene los repos remotos limpios.
struct RemoteRequestSender: Sendable {
    let client: any HTTPClient
    let encoder: JSONEncoder
    let decoder: JSONDecoder

    init(
        client: any HTTPClient,
        encoder: JSONEncoder,
        decoder: JSONDecoder
    ) {
        self.client = client
        self.encoder = encoder
        self.decoder = decoder
    }

    func send<Response: Decodable & Sendable>(
        path: String,
        method: HTTPMethod,
        token: String? = nil,
        as: Response.Type
    ) async throws -> Response {
        try await execute(path: path, method: method, body: Data?.none, token: token, as: Response.self)
    }

    func send<Body: Encodable & Sendable, Response: Decodable & Sendable>(
        path: String,
        method: HTTPMethod,
        body: Body,
        token: String? = nil,
        as: Response.Type
    ) async throws -> Response {
        let data = try encoder.encode(body)
        return try await execute(path: path, method: method, body: data, token: token, as: Response.self)
    }

    private func execute<Response: Decodable & Sendable>(
        path: String,
        method: HTTPMethod,
        body: Data?,
        token: String?,
        as: Response.Type
    ) async throws -> Response {
        let request = HTTPRequest(method: method, path: path, body: body, bearerToken: token)

        let response: HTTPClientResponse
        do {
            response = try await client.send(request)
        } catch HTTPError.offline {
            throw DomainError.transport(.offline)
        } catch {
            throw DomainError.transport(.unknown)
        }

        guard response.isSuccess else {
            throw mapServerError(status: response.status, data: response.data)
        }

        do {
            return try decoder.decode(Response.self, from: response.data)
        } catch {
            throw DomainError.transport(.decoding)
        }
    }

    private func mapServerError(status: Int, data: Data) -> DomainError {
        let payload = try? decoder.decode(ServerErrorDTO.self, from: data)
        let reason = payload?.reason

        switch status {
        case 401:
            if let reason, reason.lowercased().contains("credencial") {
                return .invalidCredentials
            }
            return .unauthenticated
        case 409:
            return .emailAlreadyExists
        default:
            return .transport(.server(message: reason ?? "HTTP \(status)"))
        }
    }
}
