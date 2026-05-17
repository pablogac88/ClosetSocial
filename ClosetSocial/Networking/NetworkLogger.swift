import Foundation

enum NetworkLogger {
    static func logRequest(method: String, url: URL, body: Data?, note: String? = nil) {
        var lines = ["🌐 → \(method) \(url.absoluteString)"]
        if let note { lines.append("   (\(note))") }
        if let body, !body.isEmpty {
            let preview = String(data: body, encoding: .utf8)?.prefix(400) ?? "<binary \(body.count) bytes>"
            lines.append("   Body: \(preview)")
        }
        print(lines.joined(separator: "\n"))
    }

    static func logResponse(status: Int, url: URL, data: Data) {
        let emoji = (200..<300).contains(status) ? "✅" : "❌"
        var lines = ["\(emoji) ← \(status) \(url.absoluteString)"]
        if !data.isEmpty {
            let preview = String(data: data, encoding: .utf8)?.prefix(600) ?? "<binary \(data.count) bytes>"
            lines.append("   Body: \(preview)")
        }
        print(lines.joined(separator: "\n"))
    }

    static func logError(_ message: String, url: URL) {
        print("💥 Error \(url.absoluteString): \(message)")
    }
}
