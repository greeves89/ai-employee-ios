import Foundation

// MARK: - WebSocket Message

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
        guard let data = text.data(using: .utf8),
              let wsMsg = try? JSONDecoder().decode(WebSocketMessage.self, from: data),
              let content = wsMsg.content else { return }

        let chatMessage = ChatMessage(
            id: wsMsg.id ?? UUID().uuidString,
            role: wsMsg.role ?? "assistant",
            content: content,
            createdAt: wsMsg.createdAt
        )
        chatMessageHandler?(chatMessage)
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
