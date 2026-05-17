import Foundation

public struct URLSessionHTTPClient: HTTPClient {
    private let baseURL: URL
    private let session: URLSession

    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    public func send(_ request: HTTPRequest) async throws -> HTTPClientResponse {
        let url = try makeURL(for: request)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = request.bearerToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        for (key, value) in request.extraHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        if let body = request.body {
            urlRequest.httpBody = body
        }

        let method = request.method.rawValue
        NetworkLogger.logRequest(method: method, url: url, body: request.body)

        do {
            let (data, response) = try await session.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw HTTPError.invalidResponse
            }
            NetworkLogger.logResponse(status: httpResponse.statusCode, url: url, data: data)
            return HTTPClientResponse(status: httpResponse.statusCode, data: data)
        } catch let error as URLError where error.code == .notConnectedToInternet {
            NetworkLogger.logError("Sin conexión", url: url)
            throw HTTPError.offline
        } catch let error as HTTPError {
            throw error
        } catch let error {
            NetworkLogger.logError(error.localizedDescription, url: url)
            throw HTTPError.unknown
        }
    }

    private func makeURL(for request: HTTPRequest) throws -> URL {
        guard let relativeURL = URL(string: request.path, relativeTo: baseURL),
              var components = URLComponents(url: relativeURL, resolvingAgainstBaseURL: true)
        else {
            throw HTTPError.invalidResponse
        }

        if !request.queryItems.isEmpty {
            let mappedItems = request.queryItems.map { item in
                URLQueryItem(name: item.name, value: item.value)
            }
            components.queryItems = (components.queryItems ?? []) + mappedItems
        }

        guard let finalURL = components.url else {
            throw HTTPError.invalidResponse
        }

        return finalURL
    }
}
