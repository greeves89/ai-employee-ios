import SwiftUI

struct AgentCard: View {
    let agent: Agent
    @ObservedObject var viewModel: AgentsViewModel
    @State private var isPulsing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                // Agent Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: agent.isRunning
                                    ? [Color(hex: "1d4ed8"), Color(hex: "4338ca")]
                                    : [Color(hex: "1e293b"), Color(hex: "334155")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Text("🤖")
                        .font(.system(size: 22))
                }

                // Agent Info
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(agent.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Spacer()

                        // Status Badge
                        StatusBadge(agent: agent)
                    }

                    if let desc = agent.description, !desc.isEmpty {
                        Text(desc)
                            .font(.system(size: 13))
                            .foregroundColor(Color.appTextSecondary)
                            .lineLimit(2)
                    }

                    if let model = agent.model {
                        HStack(spacing: 4) {
                            Image(systemName: "cpu")
                                .font(.system(size: 10))
                                .foregroundColor(Color.appTextSecondary)
                            Text(model)
                                .font(.system(size: 12))
                                .foregroundColor(Color.appTextSecondary)
                        }
                    }
                }
            }
            .padding(16)

            // Control Buttons
            if !viewModel.isActionInProgress(for: agent.id) {
                Divider()
                    .background(Color.appBorder)
                    .padding(.horizontal, 16)

                HStack(spacing: 0) {
                    // Start Button
                    AgentActionButton(
                        icon: "play.fill",
                        label: "Start",
                        color: Color.appSuccess,
                        disabled: agent.isRunning
                    ) {
                        Task { await viewModel.startAgent(agent) }
                    }

                    Divider()
                        .background(Color.appBorder)
                        .frame(height: 24)

                    // Stop Button
                    AgentActionButton(
                        icon: "stop.fill",
                        label: "Stop",
                        color: Color.appError,
                        disabled: agent.isStopped
                    ) {
                        Task { await viewModel.stopAgent(agent) }
                    }

                    Divider()
                        .background(Color.appBorder)
                        .frame(height: 24)

                    // Restart Button
                    AgentActionButton(
                        icon: "arrow.clockwise",
                        label: "Neustart",
                        color: Color.appWarning,
                        disabled: false
                    ) {
                        Task { await viewModel.restartAgent(agent) }
                    }
                }
                .padding(.vertical, 4)
            } else {
                Divider()
                    .background(Color.appBorder)
                    .padding(.horizontal, 16)

                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.appAccent))
                        .scaleEffect(0.8)
                    Text("Wird ausgefuehrt...")
                        .font(.system(size: 12))
                        .foregroundColor(Color.appTextSecondary)
                    Spacer()
                }
                .padding(.vertical, 12)
            }
        }
        .background(Color.appCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    agent.isRunning
                        ? Color.appSuccess.opacity(0.3)
                        : Color.appBorder,
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let agent: Agent
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(agent.statusColor)
                .frame(width: 7, height: 7)
                .scaleEffect(isPulsing && agent.isRunning ? 1.3 : 1.0)
                .animation(
                    agent.isRunning
                        ? Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
                        : .default,
                    value: isPulsing
                )

            Text(agent.statusLabel)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(agent.statusColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(agent.statusColor.opacity(0.12))
        .cornerRadius(20)
        .onAppear {
            isPulsing = true
        }
    }
}

// MARK: - Agent Action Button

struct AgentActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(disabled ? Color.appTextSecondary.opacity(0.4) : color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .disabled(disabled)
        .contentShape(Rectangle())
    }
}
