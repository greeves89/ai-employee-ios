import Foundation
import SwiftUI

struct ChatMessage: Identifiable, Codable {
    let id: String
    let role: String
    let content: String
    let createdAt: String?
    let attachments: [ChatAttachment]?

    enum CodingKeys: String, CodingKey {
        case id
        case role
        case content
        case createdAt = "created_at"
        case timestamp
        case attachments
        case meta
    }

    init(
        id: String,
        role: String,
        content: String,
        createdAt: String? = nil,
        attachments: [ChatAttachment]? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
        self.attachments = attachments
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Tolerate id as Int (from server) or String
        if let intId = try? container.decode(Int.self, forKey: .id) {
            self.id = String(intId)
        } else {
            self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        }

        self.role = (try? container.decode(String.self, forKey: .role)) ?? "assistant"
        self.content = (try? container.decode(String.self, forKey: .content)) ?? ""
        // History endpoint uses "timestamp"; live messages use "created_at".
        self.createdAt = (try? container.decode(String.self, forKey: .createdAt))
            ?? (try? container.decode(String.self, forKey: .timestamp))

        // Attachments may arrive at the top level (live WS file event) or inside `meta.presented_files` (history).
        if let inline = try? container.decode([ChatAttachment].self, forKey: .attachments) {
            self.attachments = inline
        } else if let meta = try? container.decode(MessageMeta.self, forKey: .meta),
                  let files = meta.presentedFiles, !files.isEmpty {
            self.attachments = files
        } else {
            self.attachments = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(role, forKey: .role)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(attachments, forKey: .attachments)
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

    var hasAttachments: Bool {
        !(attachments?.isEmpty ?? true)
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

// MARK: - Meta decoding helper

private struct MessageMeta: Decodable {
    let presentedFiles: [ChatAttachment]?

    enum CodingKeys: String, CodingKey {
        case presentedFiles = "presented_files"
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
        content == "..." && id.hasPrefix("typing_") && !hasAttachments
    }
}
