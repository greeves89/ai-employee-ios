import Foundation
import SwiftUI

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Design System Colors (Adaptive — Light & Dark Mode)

extension Color {
    /// Primary background — adapts to system appearance
    static var appBackground: Color { Color(.systemGroupedBackground) }

    /// Card / surface background — adapts to system appearance
    static var appCard: Color { Color(.secondarySystemGroupedBackground) }

    /// Secondary card — adapts to system appearance
    static var appCardSecondary: Color { Color(.tertiarySystemGroupedBackground) }

    /// Primary text — adapts to system appearance
    static var appText: Color { Color(.label) }

    /// Secondary text — adapts to system appearance
    static var appTextSecondary: Color { Color(.secondaryLabel) }

    /// Primary text (alias for legacy compatibility)
    static var appTextPrimary: Color { Color(.label) }

    /// Separator / border — adapts to system appearance
    static var appBorder: Color { Color(.separator) }

    /// Accent blue — works well in both modes
    static var appAccent: Color { Color(hex: "3b82f6") }

    /// Semantic success green
    static var appSuccess: Color { Color(hex: "22c55e") }

    /// Semantic error red
    static var appError: Color { Color(hex: "ef4444") }

    /// Semantic warning amber
    static var appWarning: Color { Color(hex: "f59e0b") }
}

// MARK: - String Date Extensions

extension String {
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let iso8601FormatterNoFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    func toDate() -> Date? {
        if let date = String.iso8601Formatter.date(from: self) {
            return date
        }
        if let date = String.iso8601FormatterNoFraction.date(from: self) {
            return date
        }
        let formatters = [
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd"
        ]
        let df = DateFormatter()
        for format in formatters {
            df.dateFormat = format
            if let date = df.date(from: self) {
                return date
            }
        }
        return nil
    }

    func formattedRelative() -> String {
        guard let date = toDate() else { return self }
        let now = Date()
        let interval = now.timeIntervalSince(date)

        if interval < 60 {
            return "Gerade eben"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "vor \(minutes) Minute\(minutes == 1 ? "" : "n")"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "vor \(hours) Stunde\(hours == 1 ? "" : "n")"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "vor \(days) Tag\(days == 1 ? "" : "en")"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            formatter.locale = Locale(identifier: "de-DE")
            return formatter.string(from: date)
        }
    }

    func formattedTime() -> String {
        guard let date = toDate() else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - View Extensions

extension View {
    func glassCard(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .glassEffect(in: .rect(cornerRadius: 16))
    }

    func shimmerEffect() -> some View {
        self
            .redacted(reason: .placeholder)
    }
}
