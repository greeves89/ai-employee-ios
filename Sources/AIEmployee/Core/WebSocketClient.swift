import Foundation

// MARK: - WebSocket Event (chat channel)

/// Raw event published by the orchestrator on `agent:{id}:chat:response`.
/// Top-level shape: `{ type, message_id, data, timestamp }`. The `data`
/// payload's shape depends on `type`:
///   - "delta":  data is a String (token-by-token streaming)
///   - "done":   data is `{ content, tool_calls, files, presented_files? }`
///   - "file":   data is `{ path, filename, media_type, size, caption }`
///   - "error":  data is `{ message }`
private struct ChatStreamEvent: Decodable {
    let type: String?
    let messageId: String?
    let timestamp: String?
    let data: JSONValue?

    enum CodingKeys: String, CodingKey {
        case type
        case messageId = "message_id"
        case timestamp
        case data
    }
}

private struct ChatDonePayload: Decodable {
    let content: String?
    let files: [ChatAttachment]?
    let presentedFiles: [ChatAttachment]?

    enum CodingKeys: String, CodingKey {
        case content
        case files
        case presentedFiles = "presented_files"
    }
}

// MARK: - Notification WebSocket Message (kept for backward compat)

struct WebSocketMessage: Codable {
    let type: String?
    let id: String?
    let role: String?
    let content: String?
    let title: String?
    let message: String?
    let notificationType: String?
    let isRead: Bool?
    let createdAt: String?
    let agentId: String?

    enum CodingKeys: String, CodingKey {
        case type
        case id
        case role
        case content
        case title
        case message
        case notificationType = "notification_type"
        case isRead = "is_read"
        case createdAt = "created_at"
        case agentId = "agent_id"
    }
}

// MARK: - WebSocket Client

@MainActor
@Observable
final class WebSocketClient: NSObject {
    static let shared = WebSocketClient()

    private var chatTask: URLSessionWebSocketTask?
    private var notificationsTask: URLSessionWebSocketTask?
    private var session: URLSession?

    private var chatMessageHandler: ((ChatMessage) -> Void)?
    private var notificationHandler: ((AINotification) -> Void)?

    private var isChatConnected = false
    private var isNotificationsConnected = false

    /// Accumulators for streaming chat events keyed by message_id.
    private var streamingContent: [String: String] = [:]
    private var streamingAttachments: [String: [ChatAttachment]] = [:]

    override private init() {
        super.init()
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.httpCookieAcceptPolicy = .always
        self.session = URLSession(configuration: config, delegate: nil, delegateQueue: OperationQueue.main)
    }

    // MARK: - Chat WebSocket

    func connectToChat(agentId: String, baseURL: String, onMessage: @escaping (ChatMessage) -> Void) {
        chatMessageHandler = onMessage
        var wsBase = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        wsBase = wsBase.replacingOccurrences(of: "https://", with: "wss://")
        wsBase = wsBase.replacingOccurrences(of: "http://", with: "ws://")

        guard let url = URL(string: "\(wsBase)/api/v1/agents/\(agentId)/chat") else { return }

        chatTask?.cancel(with: .normalClosure, reason: nil)
        chatTask = session?.webSocketTask(with: url)
        chatTask?.resume()
        isChatConnected = true
        receiveChatMessages()
    }

    func disconnectChat() {
        chatTask?.cancel(with: .normalClosure, reason: nil)
        chatTask = nil
        isChatConnected = false
        chatMessageHandler = nil
        streamingContent.removeAll()
        streamingAttachments.removeAll()
    }

    private func receiveChatMessages() {
        guard isChatConnected else { return }

        chatTask?.receive { [weak self] result in
            Task { @MainActor in
                guard let self = self, self.isChatConnected else { return }

                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        self.handleChatText(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            self.handleChatText(text)
                        }
                    @unknown default:
                        break
                    }
                    self.receiveChatMessages()

                case .failure(let error):
                    print("[WebSocket] Chat error: \(error.localizedDescription)")
                    self.isChatConnected = false
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    if self.isChatConnected == false, let handler = self.chatMessageHandler {
                        _ = handler
                    }
                }
            }
        }
    }

    private func handleChatText(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }

        // Prefer the orchestrator stream-event format ({type, message_id, data}).
        if let event = try? JSONDecoder().decode(ChatStreamEvent.self, from: data) {
            handleChatStreamEvent(event)
            return
        }

        // Fallback: flat envelope used by older code paths and tests.
        guard let wsMsg = try? JSONDecoder().decode(WebSocketMessage.self, from: data),
              let content = wsMsg.content else { return }
        let chatMessage = ChatMessage(
            id: wsMsg.id ?? UUID().uuidString,
            role: wsMsg.role ?? "assistant",
            content: content,
            createdAt: wsMsg.createdAt
        )
        chatMessageHandler?(chatMessage)
    }

    private func handleChatStreamEvent(_ event: ChatStreamEvent) {
        guard let type = event.type, let mid = event.messageId else { return }
        switch type {
        case "delta":
            if let text = event.data?.stringValue {
                streamingContent[mid, default: ""].append(text)
            }
        case "file":
            // Scheduler-generated and tool-driven attachments arrive as a standalone "file" event.
            guard case let .object(obj)? = event.data,
                  let attachment = decodeAttachment(from: obj) else { return }
            streamingAttachments[mid, default: []].append(attachment)
            // Emit immediately so the file lands in the chat even if no "done" follows
            // (e.g. when a scheduled task only published a file event without a synthesised reply).
            let standalone = ChatMessage(
                id: "\(mid)-file-\(attachment.path.hashValue)",
                role: "assistant",
                content: attachment.caption ?? "",
                createdAt: event.timestamp,
                attachments: [attachment]
            )
            chatMessageHandler?(standalone)
        case "done":
            let payload: ChatDonePayload? = (try? event.data?.decoded(as: ChatDonePayload.self))
            let accumulated = streamingContent.removeValue(forKey: mid) ?? ""
            let alreadyEmitted = streamingAttachments.removeValue(forKey: mid) ?? []
            let alreadyEmittedPaths = Set(alreadyEmitted.map { $0.path })
            // Only include attachments from "done" that weren't already pushed as standalone "file" events.
            let fromDone = (payload?.presentedFiles ?? payload?.files ?? [])
                .filter { !alreadyEmittedPaths.contains($0.path) }
            let content = payload?.content ?? accumulated
            // Skip an empty "done" if standalone file events already delivered everything.
            guard !content.isEmpty || !fromDone.isEmpty else { return }
            let chatMessage = ChatMessage(
                id: mid,
                role: "assistant",
                content: content,
                createdAt: event.timestamp,
                attachments: fromDone.isEmpty ? nil : fromDone
            )
            chatMessageHandler?(chatMessage)
        case "error":
            streamingContent.removeValue(forKey: mid)
            streamingAttachments.removeValue(forKey: mid)
        default:
            break
        }
    }

    private func decodeAttachment(from obj: [String: JSONValue]) -> ChatAttachment? {
        guard let path = obj["path"]?.stringValue, !path.isEmpty else { return nil }
        let filename = obj["filename"]?.stringValue ?? (path as NSString).lastPathComponent
        let media = obj["media_type"]?.stringValue
        let size = obj["size"]?.intValue
        let caption = obj["caption"]?.stringValue
        return ChatAttachment(
            path: path,
            filename: filename,
            mediaType: media,
            size: size,
            caption: caption?.isEmpty == true ? nil : caption
        )
    }

    // MARK: - Notifications WebSocket

    func connectToNotifications(baseURL: String, onNotification: @escaping (AINotification) -> Void) {
        notificationHandler = onNotification
        var wsBase = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        wsBase = wsBase.replacingOccurrences(of: "https://", with: "wss://")
        wsBase = wsBase.replacingOccurrences(of: "http://", with: "ws://")

        guard let url = URL(string: "\(wsBase)/api/v1/notifications") else { return }

        notificationsTask?.cancel(with: .normalClosure, reason: nil)
        notificationsTask = session?.webSocketTask(with: url)
        notificationsTask?.resume()
        isNotificationsConnected = true
        receiveNotifications()
    }

    func disconnectNotifications() {
        notificationsTask?.cancel(with: .normalClosure, reason: nil)
        notificationsTask = nil
        isNotificationsConnected = false
        notificationHandler = nil
    }

    private func receiveNotifications() {
        guard isNotificationsConnected else { return }

        notificationsTask?.receive { [weak self] result in
            Task { @MainActor in
                guard let self = self, self.isNotificationsConnected else { return }

                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        self.handleNotificationText(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            self.handleNotificationText(text)
                        }
                    @unknown default:
                        break
                    }
                    self.receiveNotifications()

                case .failure(let error):
                    print("[WebSocket] Notifications error: \(error.localizedDescription)")
                    self.isNotificationsConnected = false
                }
            }
        }
    }

    private func handleNotificationText(_ text: String) {
        guard let data = text.data(using: .utf8),
              let wsMsg = try? JSONDecoder().decode(WebSocketMessage.self, from: data),
              let id = wsMsg.id,
              let title = wsMsg.title else { return }

        let notification = AINotification(
            id: id,
            title: title,
            message: wsMsg.message,
            type: wsMsg.notificationType,
            isRead: wsMsg.isRead ?? false,
            createdAt: wsMsg.createdAt
        )
        notificationHandler?(notification)
    }

    // MARK: - Send Message

    func send(message: String) {
        let wsMessage = URLSessionWebSocketTask.Message.string(message)
        chatTask?.send(wsMessage) { error in
            if let error = error {
                print("[WebSocket] Send error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Disconnect All

    func disconnectAll() {
        disconnectChat()
        disconnectNotifications()
    }
}

// MARK: - JSONValue helper

/// Minimal JSON variant that survives arbitrary `data` payloads on the chat WebSocket.
enum JSONValue: Decodable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([JSONValue])
    case object([String: JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null; return }
        if let v = try? container.decode(Bool.self) { self = .bool(v); return }
        if let v = try? container.decode(Int.self) { self = .int(v); return }
        if let v = try? container.decode(Double.self) { self = .double(v); return }
        if let v = try? container.decode(String.self) { self = .string(v); return }
        if let v = try? container.decode([JSONValue].self) { self = .array(v); return }
        if let v = try? container.decode([String: JSONValue].self) { self = .object(v); return }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
    }

    var stringValue: String? {
        if case .string(let s) = self { return s }
        return nil
    }
    var intValue: Int? {
        switch self {
        case .int(let v): return v
        case .double(let v): return Int(v)
        case .string(let s): return Int(s)
        default: return nil
        }
    }

    /// Re-encodes this value to JSON and decodes it as the requested target type.
    func decoded<T: Decodable>(as type: T.Type) throws -> T {
        let data = try JSONEncoder().encode(self)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

extension JSONValue: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let v): try container.encode(v)
        case .int(let v): try container.encode(v)
        case .double(let v): try container.encode(v)
        case .bool(let v): try container.encode(v)
        case .array(let v): try container.encode(v)
        case .object(let v): try container.encode(v)
        case .null: try container.encodeNil()
        }
    }
}
