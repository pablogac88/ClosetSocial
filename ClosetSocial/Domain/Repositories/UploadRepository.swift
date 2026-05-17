import Foundation

public protocol UploadRepository: Sendable {
    func uploadImage(_ data: Data, mimeType: String, token: String) async throws -> URL
}
