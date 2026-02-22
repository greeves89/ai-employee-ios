import SwiftUI

struct DashboardView: View {
    @Environment(AuthManager.self) var authManager
    @State private var agentsVM = AgentsViewModel()
    @State private var approvalsVM = ApprovalsViewModel()
    @State private var notificationsVM = NotificationsViewModel()
    @State private var tasksVM = TasksViewModel()

    var body: some View {
        TabView {
            Tab("Agenten", systemImage: "cpu") {
                AgentListView(viewModel: agentsVM)
            }

            Tab("Aufgaben", systemImage: "list.bullet.clipboard") {
                TasksView(viewModel: tasksVM)
            }

            Tab("Genehmigungen", systemImage: "checkmark.shield") {
                ApprovalsView(viewModel: approvalsVM)
            }
            .badge(approvalsVM.pendingCount > 0 ? approvalsVM.pendingCount : 0)

            Tab("Benachrichtigungen", systemImage: "bell") {
                NotificationsView(viewModel: notificationsVM)
            }
            .badge(notificationsVM.unreadCount > 0 ? notificationsVM.unreadCount : 0)
        }
        .tint(Color(hex: "3b82f6"))
        .containerBackground(.regularMaterial, for: .tabView)
        .onAppear {
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
}

// MARK: - Agent List View (embedded in dashboard)

struct AgentListView: View {
    @Bindable var viewModel: AgentsViewModel
    @Environment(AuthManager.self) var authManager

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

                if viewModel.isLoading && viewModel.agents.isEmpty {
                    LoadingView(message: "Agenten werden geladen...")
                } else if viewModel.agents.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView(
                        "Keine Agenten",
                        systemImage: "cpu",
                        description: Text("Es wurden keine KI-Agenten gefunden. Fuegen Sie Agenten ueber die Web-Oberflaeche hinzu.")
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
                            .foregroundStyle(Color.appAccent)
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
                    .foregroundStyle(color)
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .glassEffect(in: .rect(cornerRadius: 14))
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
                .foregroundStyle(Color.appTextSecondary)
        }
    }
}

struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.appError)
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(in: .rect(cornerRadius: 12))
        .padding(.horizontal, 16)
        .shadow(color: .black.opacity(0.3), radius: 10)
    }
}

struct LogoutButton: View {
    @Environment(AuthManager.self) var authManager

    var body: some View {
        Button {
            Task {
                await authManager.logout()
            }
        } label: {
            Image(systemName: "rectangle.portrait.and.arrow.right")
                .foregroundStyle(Color.appTextSecondary)
        }
    }
}
