import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var agentsVM = AgentsViewModel()
    @StateObject private var approvalsVM = ApprovalsViewModel()
    @StateObject private var notificationsVM = NotificationsViewModel()
    @StateObject private var tasksVM = TasksViewModel()

    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: Agents Tab
            AgentListView(viewModel: agentsVM)
                .tabItem {
                    Label("Agenten", systemImage: "cpu")
                }
                .tag(0)

            // MARK: Tasks Tab
            TasksView(viewModel: tasksVM)
                .tabItem {
                    Label("Aufgaben", systemImage: "list.bullet.clipboard")
                }
                .tag(1)

            // MARK: Approvals Tab
            ApprovalsView(viewModel: approvalsVM)
                .tabItem {
                    Label("Genehmigungen", systemImage: "checkmark.shield")
                }
                .badge(approvalsVM.pendingCount > 0 ? approvalsVM.pendingCount : 0)
                .tag(2)

            // MARK: Notifications Tab
            NotificationsView(viewModel: notificationsVM)
                .tabItem {
                    Label("Benachrichtigungen", systemImage: "bell")
                }
                .badge(notificationsVM.unreadCount > 0 ? notificationsVM.unreadCount : 0)
                .tag(3)
        }
        .tint(Color(hex: "3b82f6"))
        .onAppear {
            configureTabBarAppearance()
            loadAllData()
        }
        .onDisappear {
            agentsVM.stopPolling()
            tasksVM.stopAutoRefresh()
            notificationsVM.disconnectWebSocket()
        }
    }

    private func loadAllData() {
        Task {
            await agentsVM.loadAgents()
            agentsVM.startPolling()
        }
        Task {
            await approvalsVM.loadApprovals()
        }
        Task {
            await notificationsVM.loadNotifications()
            notificationsVM.connectWebSocket(baseURL: authManager.baseURL)
        }
        Task {
            await tasksVM.loadTasks()
            tasksVM.startAutoRefresh()
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color(hex: "0a0f1e"))
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Agent List View (embedded in dashboard)

struct AgentListView: View {
    @ObservedObject var viewModel: AgentsViewModel
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if viewModel.isLoading && viewModel.agents.isEmpty {
                    LoadingView(message: "Agenten werden geladen...")
                } else if viewModel.agents.isEmpty && !viewModel.isLoading {
                    EmptyStateView(
                        icon: "cpu",
                        title: "Keine Agenten",
                        message: "Es wurden keine KI-Agenten gefunden. Fügen Sie Agenten über die Web-Oberfläche hinzu."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Stats Header
                            HStack(spacing: 12) {
                                StatCard(
                                    value: "\(viewModel.runningCount)",
                                    label: "Aktiv",
                                    color: Color.appSuccess,
                                    icon: "circle.fill"
                                )
                                StatCard(
                                    value: "\(viewModel.stoppedCount)",
                                    label: "Gestoppt",
                                    color: Color.appTextSecondary,
                                    icon: "circle.fill"
                                )
                                StatCard(
                                    value: "\(viewModel.agents.count)",
                                    label: "Gesamt",
                                    color: Color.appAccent,
                                    icon: "cpu"
                                )
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)

                            // Agent Cards
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.agents) { agent in
                                    NavigationLink(destination: AgentDetailView(agent: agent, agentsVM: viewModel)) {
                                        AgentCard(agent: agent, viewModel: viewModel)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                        }
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }

                // Error banner
                if let error = viewModel.errorMessage {
                    VStack {
                        Spacer()
                        ErrorBanner(message: error)
                            .padding(.bottom, 90)
                    }
                }
            }
            .navigationTitle("Meine Agenten")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await viewModel.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(Color.appAccent)
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    LogoutButton()
                }
            }
        }
    }
}

// MARK: - Supporting Components

struct StatCard: View {
    let value: String
    let label: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.appCard)
        .cornerRadius(14)
    }
}

struct LoadingView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.appAccent))
                .scaleEffect(1.5)
            Text(message)
                .font(.system(size: 15))
                .foregroundColor(Color.appTextSecondary)
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundColor(Color.appTextSecondary.opacity(0.5))

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}

struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Color.appError)
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "1e293b"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.appError.opacity(0.4), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .shadow(color: .black.opacity(0.3), radius: 10)
    }
}

struct LogoutButton: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        Button {
            Task {
                await authManager.logout()
            }
        } label: {
            Image(systemName: "rectangle.portrait.and.arrow.right")
                .foregroundColor(Color.appTextSecondary)
        }
    }
}
