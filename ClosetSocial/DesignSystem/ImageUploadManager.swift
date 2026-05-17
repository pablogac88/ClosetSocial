import UIKit

@Observable
@MainActor
public final class ImageUploadManager {

    public enum State: Equatable {
        case empty
        case localPreview(Data)
        case uploading(Data)
        case uploaded(Data, URL)
        case failed(Data, String)

        public static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.empty, .empty): return true
            case (.localPreview(let a), .localPreview(let b)): return a == b
            case (.uploading(let a), .uploading(let b)): return a == b
            case (.uploaded(let a, let u1), .uploaded(let b, let u2)): return a == b && u1 == u2
            case (.failed(let a, let m1), .failed(let b, let m2)): return a == b && m1 == m2
            default: return false
            }
        }
    }

    public private(set) var state: State = .empty

    public var localData: Data? {
        switch state {
        case .localPreview(let d), .uploading(let d), .uploaded(let d, _), .failed(let d, _): return d
        case .empty: return nil
        }
    }

    public var remoteURL: URL? {
        guard case .uploaded(_, let url) = state else { return nil }
        return url
    }

    public var isUploading: Bool {
        guard case .uploading = state else { return false }
        return true
    }

    public var isFailed: Bool {
        guard case .failed = state else { return false }
        return true
    }

    public var hasImage: Bool { state != .empty }

    public var errorMessage: String? {
        guard case .failed(_, let msg) = state else { return nil }
        return msg
    }

    public func pick(_ rawData: Data, using repository: any UploadRepository, token: String) async {
        guard !isUploading else { return }
        let data = resized(rawData)
        state = .uploading(data)
        do {
            let url = try await repository.uploadImage(data, mimeType: "image/jpeg", token: token)
            state = .uploaded(data, url)
        } catch {
            state = .failed(data, error.userMessage)
        }
    }

    public func retry(using repository: any UploadRepository, token: String) async {
        guard case .failed(let data, _) = state else { return }
        state = .uploading(data)
        do {
            let url = try await repository.uploadImage(data, mimeType: "image/jpeg", token: token)
            state = .uploaded(data, url)
        } catch {
            state = .failed(data, error.userMessage)
        }
    }

    public func remove() {
        state = .empty
    }

    // MARK: - Resize

    private func resized(_ data: Data) -> Data {
        let maxDim: CGFloat = 1200
        guard let image = UIImage(data: data) else { return data }
        let size = image.size
        guard max(size.width, size.height) > maxDim else {
            return image.jpegData(compressionQuality: 0.82) ?? data
        }
        let scale = maxDim / max(size.width, size.height)
        let newSize = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let out = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        return out.jpegData(compressionQuality: 0.82) ?? data
    }
}
