import Foundation
import SwiftUI

@MainActor
@Observable
final class ChatViewModel {
    var messages: [ChatMessage] = []
    var inputText: String = ""
    var isLoading: Bool = false
    var isSending: Bool = false
    var isTyping: Bool = false
    var errorMessage: String? = nil

    let agent: Agent
    private let webSocketClient = WebSocketClient.shared

    init(agent: Agent) {
        self.agent = agent
    }

    // MARK: - Lifecycle

    func onAppear() async {
        await loadHistory()
        connectWebSocket()
    }

    func onDisappear() {
        webSocketClient.disconnectChat()
    }

    // MARK: - History

    func loadHistory() async {
        isLoading = true
        do {
            let history = try await APIClient.shared.getChatHistory(agentId: agent.id)
            messages = history
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - WebSocket

    private func connectWebSocket() {
        guard let baseURL = UserDefaults.standard.string(forKey: "ai_employee_base_url"),
              !baseURL.isEmpty else { return }

        webSocketClient.connectToChat(agentId: agent.id, baseURL: baseURL) { [weak self] message in
            Task { @MainActor in
                guard let self = self else { return }
                self.messages.removeAll { $0.isTypingIndicator }
                self.isTyping = false
                if !self.messages.contains(where: { $0.id == message.id }) {
                    self.messages.append(message)
                }
            }
        }
    }

    // MARK: - Send Message

    func sendMessage() async {
        let content = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty, !isSending else { return }

        inputText = ""
        isSending = true
        errorMessage = nil

        let userMessage = ChatMessage(
            id: UUID().uuidString,
            role: "user",
            content: content,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        messages.append(userMessage)

        let typingMsg = ChatMessage.typingIndicator()
        messages.append(typingMsg)
        isTyping = true

        do {
            let response = try await APIClient.shared.sendMessage(agentId: agent.id, content: content)
            messages.removeAll { $0.isTypingIndicator }
            isTyping = false

            if !messages.contains(where: { $0.id == response.id }) {
                messages.append(response)
            }
        } catch let error as APIError {
            messages.removeAll { $0.isTypingIndicator }
            isTyping = false
            errorMessage = error.errorDescription
        } catch {
            messages.removeAll { $0.isTypingIndicator }
            isTyping = false
            errorMessage = error.localizedDescription
        }

        isSending = false
    }

    func sendVoiceMessage(_ text: String) async {
        guard !text.isEmpty else { return }
        inputText = text
        await sendMessage()
    }

    // MARK: - Helpers

    func clearError() {
        errorMessage = nil
    }
}
