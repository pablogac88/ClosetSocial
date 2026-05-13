import Foundation

public struct URLSessionHTTPClient: HTTPClient {
    private let baseURL: URL
    private let session: URLSession

    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    public func send(_ request: HTTPRequest) async throws -> HTTPClientResponse {
        var urlRequest = URLRequest(url: baseURL.appending(path: request.path))
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

        do {
            let (data, response) = try await session.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw HTTPError.invalidResponse
            }
            return HTTPClientResponse(status: httpResponse.statusCode, data: data)
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw HTTPError.offline
        } catch let error as HTTPError {
            throw error
        } catch {
            throw HTTPError.unknown
        }
    }
}
