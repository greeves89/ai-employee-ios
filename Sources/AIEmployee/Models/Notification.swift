import Foundation
import SwiftUI

struct AINotification: Identifiable, Codable {
    let id: String
    let title: String
    let message: String?
    let type: String?
    let isRead: Bool
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case message
        case type
        case isRead = "is_read"
        case createdAt = "created_at"
    }

    // MARK: - Computed Properties

    var typeIcon: String {
        switch type?.lowercased() {
        case "success":
            return "checkmark.circle.fill"
        case "warning":
            return "exclamationmark.triangle.fill"
        case "error":
            return "xmark.circle.fill"
        default:
            return "info.circle.fill"
        }
    }

    var typeColor: Color {
        switch type?.lowercased() {
        case "success":
            return Color(hex: "22c55e")
        case "warning":
            return Color(hex: "f59e0b")
        case "error":
            return Color(hex: "ef4444")
        default:
            return Color(hex: "3b82f6")
        }
    }

    var typeEmoji: String {
        switch type?.lowercased() {
        case "success":
            return "✅"
        case "warning":
            return "⚠️"
        case "error":
            return "❌"
        default:
            return "ℹ️"
        }
    }

    var formattedTime: String {
        guard let dateStr = createdAt else { return "" }
        return dateStr.formattedRelative()
    }
}
