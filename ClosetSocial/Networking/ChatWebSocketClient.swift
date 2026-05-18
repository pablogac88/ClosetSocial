import Foundation

@MainActor
public final class ChatWebSocketClient {
    public enum ConnectionState: Sendable, Equatable {
        case disconnected
        case connecting
        case connected
    }

    public private(set) var state: ConnectionState = .disconnected

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let isEnabled: Bool

    private var currentToken: String?
    private var isManualDisconnect = false
    private var reconnectAttempt = 0
    private var webSocketTask: URLSessionWebSocketTask?
    private var receiveTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var continuations: [UUID: AsyncStream<ChatSocketEvent>.Continuation] = [:]

    public init(
        baseURL: URL,
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        isEnabled: Bool = true
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
        self.isEnabled = isEnabled
        self.decoder.dateDecodingStrategy = .iso8601
    }

    deinit {
        receiveTask?.cancel()
        reconnectTask?.cancel()
    }

    public func stream() -> AsyncStream<ChatSocketEvent> {
        let id = UUID()
        return AsyncStream { continuation in
            continuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    self?.continuations.removeValue(forKey: id)
                }
            }
        }
    }

    public func connect(token: String) async {
        guard isEnabled else { return }

        if currentToken == token, (state == .connected || state == .connecting) {
            return
        }

        currentToken = token
        isManualDisconnect = false
        reconnectAttempt = 0
        reconnectTask?.cancel()
        reconnectTask = nil
        await openConnection()
    }

    public func disconnect() async {
        isManualDisconnect = true
        reconnectTask?.cancel()
        reconnectTask = nil
        receiveTask?.cancel()
        receiveTask = nil
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        state = .disconnected
    }

    private func openConnection() async {
        guard isEnabled, let token = currentToken else { return }

        receiveTask?.cancel()
        webSocketTask?.cancel(with: .goingAway, reason: nil)

        let request = makeURLRequest(token: token)
        let task = session.webSocketTask(with: request)
        webSocketTask = task
        state = .connecting
        task.resume()

        receiveTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.receiveLoop(for: task)
        }
    }

    private func receiveLoop(for task: URLSessionWebSocketTask) async {
        while !Task.isCancelled, webSocketTask === task {
            do {
                let message = try await task.receive()
                state = .connected
                reconnectAttempt = 0

                let data: Data
                switch message {
                case let .string(text):
                    data = Data(text.utf8)
                case let .data(rawData):
                    data = rawData
                @unknown default:
                    continue
                }

                guard let dto = try? decoder.decode(ChatSocketEventDTO.self, from: data),
                      let event = dto.toDomain()
                else {
                    continue
                }

                publish(event)
            } catch {
                guard !isManualDisconnect else { break }
                await scheduleReconnect()
                break
            }
        }
    }

    private func scheduleReconnect() async {
        guard isEnabled, !isManualDisconnect, currentToken != nil else {
            state = .disconnected
            return
        }

        reconnectTask?.cancel()
        state = .disconnected
        let delay = min(pow(2.0, Double(reconnectAttempt)), 15.0)
        reconnectAttempt += 1

        reconnectTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled, !self.isManualDisconnect else { return }
            await self.openConnection()
        }
    }

    private func publish(_ event: ChatSocketEvent) {
        for continuation in continuations.values {
            continuation.yield(event)
        }
    }

    private func makeURLRequest(token: String) -> URLRequest {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.scheme = baseURL.scheme == "https" ? "wss" : "ws"
        components?.path = "/ws/chat"
        components?.query = nil

        let url = components?.url ?? baseURL
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}
