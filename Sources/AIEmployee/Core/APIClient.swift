import Foundation

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidURL
    case notAuthenticated
    case serverError(Int, String)
    case decodingError(String)
    case networkError(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Ungültige Server-URL"
        case .notAuthenticated:
            return "Nicht angemeldet. Bitte erneut einloggen."
        case .serverError(let code, let message):
            return "Serverfehler \(code): \(message)"
        case .decodingError(let detail):
            return "Datenfehler: \(detail)"
        case .networkError(let message):
            return "Netzwerkfehler: \(message)"
        case .unknown:
            return "Unbekannter Fehler"
        }
    }
}

// MARK: - Response Types

struct LoginResponse: Codable {
    let accessToken: String?
    let tokenType: String?
    let user: User?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case user
    }
}

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String?
    let role: String?
    let isActive: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case role
        case isActive = "is_active"
    }
}

struct MessageResponse: Codable {
    let id: String?
    let role: String?
    let content: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case role
        case content
        case createdAt = "created_at"
    }
}

// MARK: - API Client

@MainActor
final class APIClient {
    static let shared = APIClient()

    private var session: URLSession
    private var baseURL: String = ""
    private var cookieStorage: HTTPCookieStorage

    private init() {
        cookieStorage = HTTPCookieStorage.shared
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = cookieStorage
        config.httpCookieAcceptPolicy = .always
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
    }

    func configure(baseURL: String) {
        self.baseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    // MARK: - Private Helpers

    private func makeURL(_ path: String) throws -> URL {
        guard !baseURL.isEmpty else { throw APIError.invalidURL }
        let fullURL = "\(baseURL)\(path)"
        guard let url = URL(string: fullURL) else { throw APIError.invalidURL }
        return url
    }

    private func makeRequest(_ path: String, method: String = "GET", body: Data? = nil) throws -> URLRequest {
        let url = try makeURL(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = body
        return request
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unknown
            }

            if httpResponse.statusCode == 401 {
                throw APIError.notAuthenticated
            }

            if httpResponse.statusCode >= 400 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unbekannter Fehler"
                throw APIError.serverError(httpResponse.statusCode, errorMessage)
            }

            let decoder = JSONDecoder()
            do {
                return try decoder.decode(T.self, from: data)
            } catch let decodingError {
                throw APIError.decodingError(decodingError.localizedDescription)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error.localizedDescription)
        }
    }

    private func performVoid(_ request: URLRequest) async throws {
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unknown
            }

            if httpResponse.statusCode == 401 {
                throw APIError.notAuthenticated
            }

            if httpResponse.statusCode >= 400 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unbekannter Fehler"
                throw APIError.serverError(httpResponse.statusCode, errorMessage)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error.localizedDescription)
        }
    }

    // MARK: - Auth

    func login(email: String, password: String) async throws -> User {
        let body = ["email": email, "password": password]
        let bodyData = try JSONEncoder().encode(body)
        let request = try makeRequest("/api/v1/auth/login", method: "POST", body: bodyData)
        let response: LoginResponse = try await perform(request)
        guard let user = response.user else {
            throw APIError.serverError(500, "Keine Benutzerdaten in der Antwort")
        }
        return user
    }

    func logout() async {
        guard let request = try? makeRequest("/api/v1/auth/logout", method: "POST") else { return }
        _ = try? await performVoid(request)
        // Clear all cookies for the base URL
        if let url = URL(string: baseURL),
           let cookies = cookieStorage.cookies(for: url) {
            for cookie in cookies {
                cookieStorage.deleteCookie(cookie)
            }
        }
    }

    // MARK: - Agents

    func getAgents() async throws -> [Agent] {
        let request = try makeRequest("/api/v1/agents")
        return try await perform(request)
    }

    func startAgent(id: String) async throws {
        let request = try makeRequest("/api/v1/agents/\(id)/start", method: "POST")
        try await performVoid(request)
    }

    func stopAgent(id: String) async throws {
        let request = try makeRequest("/api/v1/agents/\(id)/stop", method: "POST")
        try await performVoid(request)
    }

    func restartAgent(id: String) async throws {
        let request = try makeRequest("/api/v1/agents/\(id)/restart", method: "POST")
        try await performVoid(request)
    }

    // MARK: - Chat

    func sendMessage(agentId: String, content: String) async throws -> ChatMessage {
        let body = ["content": content]
        let bodyData = try JSONEncoder().encode(body)
        let request = try makeRequest("/api/v1/agents/\(agentId)/message", method: "POST", body: bodyData)
        let response: MessageResponse = try await perform(request)
        return ChatMessage(
            id: response.id ?? UUID().uuidString,
            role: response.role ?? "assistant",
            content: response.content ?? "",
            createdAt: response.createdAt
        )
    }

    func getChatHistory(agentId: String) async throws -> [ChatMessage] {
        let request = try makeRequest("/api/v1/agents/\(agentId)/chat/history")
        return try await perform(request)
    }

    // MARK: - Tasks

    func getTasks() async throws -> [AITask] {
        let request = try makeRequest("/api/v1/tasks")
        return try await perform(request)
    }

    // MARK: - Approvals

    func getPendingApprovals() async throws -> [Approval] {
        let request = try makeRequest("/api/v1/approvals/pending")
        return try await perform(request)
    }

    func approveCommand(id: String) async throws {
        let request = try makeRequest("/api/v1/approvals/\(id)/approve", method: "POST")
        try await performVoid(request)
    }

    func denyCommand(id: String) async throws {
        let request = try makeRequest("/api/v1/approvals/\(id)/deny", method: "POST")
        try await performVoid(request)
    }

    // MARK: - Notifications

    func getNotifications() async throws -> [AINotification] {
        let request = try makeRequest("/api/v1/notifications")
        return try await perform(request)
    }

    func markNotificationRead(id: String) async throws {
        let request = try makeRequest("/api/v1/notifications/\(id)/read", method: "POST")
        try await performVoid(request)
    }

    // MARK: - WebSocket URL Builder

    func webSocketURL(path: String) -> URL? {
        guard !baseURL.isEmpty else { return nil }
        var wsBase = baseURL
        wsBase = wsBase.replacingOccurrences(of: "https://", with: "wss://")
        wsBase = wsBase.replacingOccurrences(of: "http://", with: "ws://")
        return URL(string: "\(wsBase)\(path)")
    }
}
