import SwiftUI

struct AgentDetailView: View {
    let agent: Agent
    @Bindable var agentsVM: AgentsViewModel
    @State private var selectedTab: Int = 0
    @State private var localAgent: Agent

    init(agent: Agent, agentsVM: AgentsViewModel) {
        self.agent = agent
        self.agentsVM = agentsVM
        self._localAgent = State(initialValue: agent)
    }

    var body: some View {
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

            VStack(spacing: 0) {
                // Agent Header Card
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: localAgent.isRunning
                                            ? [Color(hex: "1d4ed8"), Color(hex: "4338ca")]
                                            : [Color(hex: "1e293b"), Color(hex: "334155")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                                .shadow(color: localAgent.isRunning ? Color(hex: "3b82f6").opacity(0.4) : .clear, radius: 12)

                            Image(systemName: "cpu.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(localAgent.name)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)

                            StatusBadge(agent: localAgent)
                        }

                        Spacer()
                    }

                    // Control Buttons
                    HStack(spacing: 12) {
                        DetailControlButton(
                            icon: "play.fill",
                            label: "Starten",
                            color: Color.appSuccess,
                            disabled: localAgent.isRunning || agentsVM.isActionInProgress(for: localAgent.id)
                        ) {
                            Task {
                                await agentsVM.startAgent(localAgent)
                                refreshLocalAgent()
                            }
                        }

                        DetailControlButton(
                            icon: "stop.fill",
                            label: "Stoppen",
                            color: Color.appError,
                            disabled: localAgent.isStopped || agentsVM.isActionInProgress(for: localAgent.id)
                        ) {
                            Task {
                                await agentsVM.stopAgent(localAgent)
                                refreshLocalAgent()
                            }
                        }

                        DetailControlButton(
                            icon: "arrow.clockwise",
                            label: "Neustart",
                            color: Color.appWarning,
                            disabled: agentsVM.isActionInProgress(for: localAgent.id)
                        ) {
                            Task {
                                await agentsVM.restartAgent(localAgent)
                                refreshLocalAgent()
                            }
                        }
                    }
                }
                .padding(20)
                .glassEffect(in: .rect(cornerRadius: 0))

                // Tab Picker
                Picker("Ansicht", selection: $selectedTab) {
                    Text("Chat").tag(0)
                    Text("Info").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // Tab Content
                if selectedTab == 0 {
                    ChatView(agent: localAgent)
                } else {
                    AgentInfoView(agent: localAgent)
                }
            }
        }
        .navigationTitle(localAgent.name)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: agentsVM.agents) { _, agents in
            if let updated = agents.first(where: { $0.id == agent.id }) {
                localAgent = updated
            }
        }
    }

    private func refreshLocalAgent() {
        if let updated = agentsVM.agents.first(where: { $0.id == agent.id }) {
            localAgent = updated
        }
    }
}

// MARK: - Detail Control Button

struct DetailControlButton: View {
    let icon: String
    let label: String
    let color: Color
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(disabled ? Color.appTextSecondary : color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .glassEffect(in: .rect(cornerRadius: 12))
        }
        .disabled(disabled)
    }
}

// MARK: - Agent Info View

struct AgentInfoView: View {
    let agent: Agent

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                InfoSection(title: "Allgemein") {
                    InfoRow(label: "Name", value: agent.name, icon: "person.fill")
                    InfoRow(label: "Status", value: agent.statusLabel, icon: "circle.fill", valueColor: agent.statusColor)
                    if let model = agent.model {
                        InfoRow(label: "Modell", value: model, icon: "cpu")
                    }
                    if let date = agent.formattedDate {
                        InfoRow(label: "Erstellt", value: date, icon: "calendar")
                    }
                }

                if let desc = agent.description, !desc.isEmpty {
                    InfoSection(title: "Beschreibung") {
                        Text(desc)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.appTextSecondary)
                            .padding(.vertical, 4)
                    }
                }
            }
            .padding(16)
        }
    }
}

struct InfoSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.appTextSecondary)
                .textCase(.uppercase)
                .tracking(0.5)

            VStack(spacing: 0) {
                content
            }
            .glassEffect(in: .rect(cornerRadius: 14))
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    let icon: String
    var valueColor: Color = .white

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.appAccent)
                .frame(width: 20)

            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(Color.appTextSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(valueColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .overlay(
            Divider()
                .background(Color.appBorder),
            alignment: .bottom
        )
    }
}
