import Foundation
import SwiftUI

struct AITask: Identifiable, Codable {
    let id: String
    let title: String
    let status: String
    let agentId: String?
    let agentName: String?
    let createdAt: String?
    let completedAt: String?
    let output: String?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case status
        case agentId = "agent_id"
        case agentName = "agent_name"
        case createdAt = "created_at"
        case completedAt = "completed_at"
        case output
        case description
    }

    // MARK: - Computed Properties

    var statusColor: Color {
        switch status.lowercased() {
        case "completed", "done":
            return Color(hex: "22c55e")
        case "running", "in_progress", "active":
            return Color(hex: "3b82f6")
        case "failed", "error":
            return Color(hex: "ef4444")
        case "pending", "waiting":
            return Color(hex: "94a3b8")
        case "cancelled":
            return Color(hex: "f59e0b")
        default:
            return Color(hex: "94a3b8")
        }
    }

    var statusLabel: String {
        switch status.lowercased() {
        case "completed", "done":
            return "Abgeschlossen"
        case "running", "in_progress", "active":
            return "Laufend"
        case "failed", "error":
            return "Fehlgeschlagen"
        case "pending", "waiting":
            return "Ausstehend"
        case "cancelled":
            return "Abgebrochen"
        default:
            return status.capitalized
        }
    }

    var statusIcon: String {
        switch status.lowercased() {
        case "completed", "done":
            return "checkmark.circle.fill"
        case "running", "in_progress", "active":
            return "arrow.clockwise.circle.fill"
        case "failed", "error":
            return "xmark.circle.fill"
        case "pending", "waiting":
            return "clock.fill"
        case "cancelled":
            return "minus.circle.fill"
        default:
            return "circle.fill"
        }
    }

    var isRunning: Bool {
        ["running", "in_progress", "active"].contains(status.lowercased())
    }

    var formattedCreatedAt: String? {
        createdAt?.formattedRelative()
    }

    var formattedCompletedAt: String? {
        completedAt?.formattedRelative()
    }
}
