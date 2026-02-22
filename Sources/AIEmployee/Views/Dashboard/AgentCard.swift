import SwiftUI

struct AgentCard: View {
    let agent: Agent
    @Bindable var viewModel: AgentsViewModel
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

                    Image(systemName: "cpu.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                }

                // Agent Info
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(agent.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Spacer()

                        StatusBadge(agent: agent)
                    }

                    if let desc = agent.description, !desc.isEmpty {
                        Text(desc)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.appTextSecondary)
                            .lineLimit(2)
                    }

                    if let model = agent.model {
                        HStack(spacing: 4) {
                            Image(systemName: "cpu")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.appTextSecondary)
                            Text(model)
                                .font(.system(size: 12))
                                .foregroundStyle(Color.appTextSecondary)
                        }
                    }
                }
            }
            .padding(16)

            // Control Buttons — wrapped in GlassEffectContainer so they morph together
            if !viewModel.isActionInProgress(for: agent.id) {
                Divider()
                    .background(Color.appBorder)
                    .padding(.horizontal, 16)

                GlassEffectContainer(spacing: 0) {
                    HStack(spacing: 0) {
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
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
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
                        .foregroundStyle(Color.appTextSecondary)
                    Spacer()
                }
                .padding(.vertical, 12)
            }
        }
        .glassEffect(in: .rect(cornerRadius: 16))
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
                .foregroundStyle(agent.statusColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .glassEffect(in: .capsule)
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
            .foregroundStyle(disabled ? Color.appTextSecondary.opacity(0.4) : color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .disabled(disabled)
        .contentShape(Rectangle())
    }
}
