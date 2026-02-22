import Foundation
import SwiftUI

@MainActor
final class NotificationsViewModel: ObservableObject {
    @Published var notifications: [AINotification] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let webSocketClient = WebSocketClient.shared

    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    var unreadNotifications: [AINotification] {
        notifications.filter { !$0.isRead }
    }

    var readNotifications: [AINotification] {
        notifications.filter { $0.isRead }
    }

    // MARK: - Load Notifications

    func loadNotifications() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            notifications = try await APIClient.shared.getNotifications()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() async {
        await loadNotifications()
    }

    // MARK: - WebSocket

    func connectWebSocket(baseURL: String) {
        webSocketClient.connectToNotifications(baseURL: baseURL) { [weak self] notification in
            Task { @MainActor in
                guard let self = self else { return }
                if !self.notifications.contains(where: { $0.id == notification.id }) {
                    self.notifications.insert(notification, at: 0)
                }
            }
        }
    }

    func disconnectWebSocket() {
        webSocketClient.disconnectNotifications()
    }

    // MARK: - Mark Read

    func markRead(_ notification: AINotification) async {
        guard !notification.isRead else { return }

        do {
            try await APIClient.shared.markNotificationRead(id: notification.id)
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                let updated = AINotification(
                    id: notification.id,
                    title: notification.title,
                    message: notification.message,
                    type: notification.type,
                    isRead: true,
                    createdAt: notification.createdAt
                )
                notifications[index] = updated
            }
        } catch {
            // Silently ignore mark-read errors
            print("[NotificationsVM] Mark read error: \(error)")
        }
    }

    func markAllRead() async {
        let unread = notifications.filter { !$0.isRead }
        for notification in unread {
            await markRead(notification)
        }
    }
}
