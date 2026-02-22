import Foundation
import SwiftUI

struct ChatMessage: Identifiable, Codable {
    let id: String
    let role: String
    let content: String
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case role
        case content
        case createdAt = "created_at"
    }

    // MARK: - Computed Properties

    var isUser: Bool {
        role.lowercased() == "user"
    }

    var isAssistant: Bool {
        role.lowercased() == "assistant" || role.lowercased() == "agent"
    }

    var isSystem: Bool {
        role.lowercased() == "system"
    }

    var formattedTime: String {
        guard let dateStr = createdAt else { return "" }
        return dateStr.formattedTime()
    }

    var formattedRelative: String {
        guard let dateStr = createdAt else { return "" }
        return dateStr.formattedRelative()
    }

    var bubbleColor: Color {
        if isUser {
            return Color(hex: "3b82f6")
        } else {
            return Color(hex: "1e293b")
        }
    }

    var textColor: Color {
        return .white
    }
}

// MARK: - Typing Indicator Message (local only)

extension ChatMessage {
    static func typingIndicator() -> ChatMessage {
        ChatMessage(
            id: "typing_\(UUID().uuidString)",
            role: "assistant",
            content: "...",
            createdAt: nil
        )
    }

    var isTypingIndicator: Bool {
        content == "..." && id.hasPrefix("typing_")
    }
}
