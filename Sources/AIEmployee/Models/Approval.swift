import Foundation
import SwiftUI

struct Approval: Identifiable, Codable {
    let id: String
    let command: String
    let riskLevel: String?
    let agentId: String?
    let agentName: String?
    let createdAt: String?
    let description: String?
    let options: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case command
        case riskLevel = "risk_level"
        case agentId = "agent_id"
        case agentName = "agent_name"
        case createdAt = "created_at"
        case description
        case options
    }

    // MARK: - Computed Properties

    var riskColor: Color {
        switch riskLevel?.lowercased() {
        case "high", "critical":
            return Color(hex: "ef4444")
        case "medium", "moderate":
            return Color(hex: "f59e0b")
        case "low":
            return Color(hex: "22c55e")
        default:
            return Color(hex: "94a3b8")
        }
    }

    var riskLabel: String {
        switch riskLevel?.lowercased() {
        case "high", "critical":
            return "Hohes Risiko"
        case "medium", "moderate":
            return "Mittleres Risiko"
        case "low":
            return "Geringes Risiko"
        default:
            return riskLevel?.capitalized ?? "Unbekannt"
        }
    }

    var riskIcon: String {
        switch riskLevel?.lowercased() {
        case "high", "critical":
            return "exclamationmark.triangle.fill"
        case "medium", "moderate":
            return "exclamationmark.circle.fill"
        case "low":
            return "checkmark.shield.fill"
        default:
            return "shield.fill"
        }
    }

    var formattedTime: String {
        guard let dateStr = createdAt else { return "" }
        return dateStr.formattedRelative()
    }
}
