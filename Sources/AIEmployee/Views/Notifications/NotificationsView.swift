import SwiftUI

struct NotificationsView: View {
    @ObservedObject var viewModel: NotificationsViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    LoadingView(message: "Benachrichtigungen werden geladen...")
                } else if viewModel.notifications.isEmpty && !viewModel.isLoading {
                    EmptyStateView(
                        icon: "bell.slash.fill",
                        title: "Keine Benachrichtigungen",
                        message: "Sie haben noch keine Benachrichtigungen erhalten."
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                            // Unread Section
                            if !viewModel.unreadNotifications.isEmpty {
                                Section {
                                    ForEach(viewModel.unreadNotifications) { notification in
                                        NotificationRow(notification: notification, isUnread: true)
                                            .onTapGesture {
                                                Task { await viewModel.markRead(notification) }
                                            }
                                        Divider()
                                            .background(Color.appBorder)
                                            .padding(.leading, 58)
                                    }
                                } header: {
                                    SectionHeader(title: "Ungelesen (\(viewModel.unreadCount))")
                                }
                            }

                            // Read Section
                            if !viewModel.readNotifications.isEmpty {
                                Section {
                                    ForEach(viewModel.readNotifications) { notification in
                                        NotificationRow(notification: notification, isUnread: false)
                                        Divider()
                                            .background(Color.appBorder)
                                            .padding(.leading, 58)
                                    }
                                } header: {
                                    SectionHeader(title: "Gelesen")
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }

                // Error
                if let error = viewModel.errorMessage {
                    VStack {
                        Spacer()
                        ErrorBanner(message: error)
                            .padding(.bottom, 90)
                    }
                }
            }
            .navigationTitle("Benachrichtigungen")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if viewModel.unreadCount > 0 {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            Task { await viewModel.markAllRead() }
                        } label: {
                            Text("Alle gelesen")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.appAccent)
                        }
                    }
                }
            }
            .task {
                await viewModel.loadNotifications()
            }
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.appTextSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.appBackground)
    }
}

// MARK: - Notification Row

struct NotificationRow: View {
    let notification: AINotification
    let isUnread: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Unread Indicator + Icon
            HStack(spacing: 0) {
                // Blue left border for unread
                Rectangle()
                    .fill(isUnread ? Color.appAccent : Color.clear)
                    .frame(width: 3)

                // Type Icon
                ZStack {
                    Circle()
                        .fill(notification.typeColor.opacity(0.15))
                        .frame(width: 38, height: 38)

                    Image(systemName: notification.typeIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(notification.typeColor)
                }
                .padding(.leading, 13)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(notification.title)
                        .font(.system(size: 15, weight: isUnread ? .semibold : .regular))
                        .foregroundColor(isUnread ? .white : Color.appTextSecondary)
                        .lineLimit(2)

                    Spacer()

                    // Unread dot
                    if isUnread {
                        Circle()
                            .fill(Color.appAccent)
                            .frame(width: 8, height: 8)
                    }
                }

                if let message = notification.message, !message.isEmpty {
                    Text(message)
                        .font(.system(size: 13))
                        .foregroundColor(Color.appTextSecondary)
                        .lineLimit(3)
                }

                if !notification.formattedTime.isEmpty {
                    Text(notification.formattedTime)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "475569"))
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.trailing, 16)
        .background(
            isUnread
                ? Color.appAccent.opacity(0.04)
                : Color.clear
        )
        .contentShape(Rectangle())
    }
}
