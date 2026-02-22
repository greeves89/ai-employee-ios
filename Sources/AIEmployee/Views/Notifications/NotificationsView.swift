import SwiftUI

struct NotificationsView: View {
    @Bindable var viewModel: NotificationsViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                MeshGradient(width: 3, height: 3, points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [0.5, 0.5], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ], colors: [
                    Color(hex: "0a0f1e"), Color(hex: "0f1b35"), Color(hex: "0a0f1e"),
                    Color(hex: "0f1b35"), Color(hex: "1a2744"), Color(hex: "0f1b35"),
                    Color(hex: "0a0f1e"), Color(hex: "0f1b35"), Color(hex: "0a0f1e")
                ])
                .ignoresSafeArea()

                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    LoadingView(message: "Benachrichtigungen werden geladen...")
                } else if viewModel.notifications.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView(
                        "Keine Benachrichtigungen",
                        systemImage: "bell.slash.fill",
                        description: Text("Sie haben noch keine Benachrichtigungen erhalten.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
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
                                .foregroundStyle(Color.appAccent)
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
                .foregroundStyle(Color.appTextSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Notification Row

struct NotificationRow: View {
    let notification: AINotification
    let isUnread: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(isUnread ? Color.appAccent : Color.clear)
                    .frame(width: 3)

                ZStack {
                    Circle()
                        .fill(notification.typeColor.opacity(0.15))
                        .frame(width: 38, height: 38)

                    Image(systemName: notification.typeIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(notification.typeColor)
                }
                .padding(.leading, 13)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(notification.title)
                        .font(.system(size: 15, weight: isUnread ? .semibold : .regular))
                        .foregroundStyle(isUnread ? .white : Color.appTextSecondary)
                        .lineLimit(2)

                    Spacer()

                    if isUnread {
                        Circle()
                            .fill(Color.appAccent)
                            .frame(width: 8, height: 8)
                    }
                }

                if let message = notification.message, !message.isEmpty {
                    Text(message)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(3)
                }

                if !notification.formattedTime.isEmpty {
                    Text(notification.formattedTime)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "475569"))
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
