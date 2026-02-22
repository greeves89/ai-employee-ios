import Foundation
import SwiftUI

struct Agent: Identifiable, Codable {
    let id: String
    let name: String
    let description: String?
    let status: String
    let model: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case status
        case model
        case createdAt = "created_at"
    }

    // MARK: - Computed Properties

    var isRunning: Bool {
        status.lowercased() == "running"
    }

    var isStopped: Bool {
        status.lowercased() == "stopped" || status.lowercased() == "idle"
    }

    var isError: Bool {
        status.lowercased() == "error" || status.lowercased() == "failed"
    }

    var statusColor: Color {
        switch status.lowercased() {
        case "running", "active":
            return Color(hex: "22c55e")
        case "stopped", "idle":
            return Color(hex: "94a3b8")
        case "error", "failed":
            return Color(hex: "ef4444")
        case "starting", "restarting":
            return Color(hex: "f59e0b")
        default:
            return Color(hex: "94a3b8")
        }
    }

    var statusLabel: String {
        switch status.lowercased() {
        case "running", "active":
            return "Aktiv"
        case "stopped", "idle":
            return "Gestoppt"
        case "error", "failed":
            return "Fehler"
        case "starting":
            return "Startet..."
        case "restarting":
            return "Neustart..."
        default:
            return status.capitalized
        }
    }

    var statusIcon: String {
        switch status.lowercased() {
        case "running", "active":
            return "circle.fill"
        case "stopped", "idle":
            return "circle.fill"
        case "error", "failed":
            return "exclamationmark.circle.fill"
        case "starting", "restarting":
            return "arrow.clockwise.circle.fill"
        default:
            return "circle.fill"
        }
    }

    var formattedDate: String? {
        guard let dateStr = createdAt else { return nil }
        return dateStr.formattedRelative()
    }
}
