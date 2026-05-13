import Foundation

/// Cliente HTTP abstracto. Las implementaciones devuelven datos crudos + status.
/// El parsing y el manejo de errores lógicos vive arriba (Data layer).
public protocol HTTPClient: Sendable {
    func send(_ request: HTTPRequest) async throws -> HTTPClientResponse
}

public struct HTTPClientResponse: Sendable {
    public let status: Int
    public let data: Data

    public init(status: Int, data: Data) {
        self.status = status
        self.data = data
    }

    public var isSuccess: Bool {
        (200..<300).contains(status)
    }
}
