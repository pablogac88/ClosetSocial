import Foundation

public struct RemoteUploadRepository: UploadRepository {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(baseURL: URL, session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
    }

    public func uploadImage(_ data: Data, mimeType: String, token: String) async throws -> URL {
        let endpoint = ClosetSocialEndpoint.uploadImage
        guard let url = URL(string: endpoint, relativeTo: baseURL) else {
            throw DomainError.transport(.unknown)
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        let body = buildMultipartBody(data: data, mimeType: mimeType, boundary: boundary)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = body

        NetworkLogger.logRequest(method: "POST", url: url, body: nil, note: "multipart/form-data \(body.count) bytes")

        let (responseData, response): (Data, URLResponse)
        do {
            (responseData, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .notConnectedToInternet {
            NetworkLogger.logError("Sin conexión", url: url)
            throw DomainError.transport(.offline)
        } catch {
            NetworkLogger.logError(error.localizedDescription, url: url)
            throw DomainError.transport(.unknown)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DomainError.transport(.unknown)
        }
        NetworkLogger.logResponse(status: httpResponse.statusCode, url: url, data: responseData)
        guard (200..<300).contains(httpResponse.statusCode) else {
            let payload = try? decoder.decode(ServerErrorDTO.self, from: responseData)
            let reason = payload?.reason ?? "HTTP \(httpResponse.statusCode)"
            throw DomainError.transport(.server(message: reason))
        }

        let dto = try decoder.decode(UploadResponseDTO.self, from: responseData)
        guard let resultURL = URL(string: dto.url) else {
            throw DomainError.transport(.decoding)
        }
        return resultURL
    }

    private func buildMultipartBody(data: Data, mimeType: String, boundary: String) -> Data {
        var body = Data()
        let crlf = "\r\n"
        let boundaryPrefix = "--\(boundary)\(crlf)"

        body.append(boundaryPrefix.utf8Data)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"upload\"\(crlf)".utf8Data)
        body.append("Content-Type: \(mimeType)\(crlf)".utf8Data)
        body.append(crlf.utf8Data)
        body.append(data)
        body.append(crlf.utf8Data)
        body.append("--\(boundary)--\(crlf)".utf8Data)
        return body
    }
}

private extension String {
    var utf8Data: Data { Data(utf8) }
}
