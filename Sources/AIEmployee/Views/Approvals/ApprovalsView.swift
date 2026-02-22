import SwiftUI

struct ApprovalsView: View {
    @Bindable var viewModel: ApprovalsViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                meshGradientBackground
                    .ignoresSafeArea()

                if viewModel.isLoading && viewModel.approvals.isEmpty {
                    LoadingView(message: "Genehmigungen werden geladen...")
                } else if viewModel.approvals.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView {
                        Label("Keine ausstehenden Genehmigungen", systemImage: "checkmark.shield.fill")
                            .foregroundStyle(Color.appSuccess)
                    } description: {
                        Text("Alle Aktionen wurden genehmigt.")
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            if !viewModel.approvals.isEmpty {
                                HStack(spacing: 10) {
                                    Image(systemName: "exclamationmark.shield.fill")
                                        .foregroundStyle(Color.appWarning)
                                    Text("\(viewModel.approvals.count) Aktion\(viewModel.approvals.count == 1 ? "" : "en") warten auf Ihre Genehmigung")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(Color.appWarning)
                                    Spacer()
                                }
                                .padding(14)
                                .glassEffect(in: .rect(cornerRadius: 12))
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                            }

                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.approvals) { approval in
                                    ApprovalCard(approval: approval, viewModel: viewModel)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
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
            .navigationTitle("Genehmigungen")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadApprovals()
            }
        }
    }

    @ViewBuilder
    private var meshGradientBackground: some View {
        if colorScheme == .dark {
            MeshGradient(width: 3, height: 3, points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.5, 0.5], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1]
            ], colors: [
                Color(hex: "0a0f1e"), Color(hex: "0f1b35"), Color(hex: "0a0f1e"),
                Color(hex: "0f1b35"), Color(hex: "1a2744"), Color(hex: "0f1b35"),
                Color(hex: "0a0f1e"), Color(hex: "0f1b35"), Color(hex: "0a0f1e")
            ])
        } else {
            MeshGradient(width: 3, height: 3, points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.5, 0.5], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1]
            ], colors: [
                Color(hex: "e0f2fe"), Color(hex: "bfdbfe"), Color(hex: "e0f2fe"),
                Color(hex: "bfdbfe"), Color(hex: "dbeafe"), Color(hex: "bfdbfe"),
                Color(hex: "e0f2fe"), Color(hex: "bfdbfe"), Color(hex: "e0f2fe")
            ])
        }
    }
}

// MARK: - Approval Card

struct ApprovalCard: View {
    let approval: Approval
    @Bindable var viewModel: ApprovalsViewModel

    var isProcessing: Bool {
        viewModel.isProcessing(approval.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header: Agent + Risk
            HStack {
                if let agentName = approval.agentName {
                    Label(agentName, systemImage: "cpu")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.appTextSecondary)
                }
                Spacer()

                HStack(spacing: 5) {
                    Image(systemName: approval.riskIcon)
                        .font(.system(size: 11))
                    Text(approval.riskLabel)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(approval.riskColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(approval.riskColor.opacity(0.12))
                .clipShape(.rect(cornerRadius: 8))
            }

            // Command (monospace style)
            VStack(alignment: .leading, spacing: 6) {
                Text("Befehl:")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.appTextSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                ScrollView(.horizontal, showsIndicators: false) {
                    Text(approval.command)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Color(hex: "a5f3fc"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                }
                .glassEffect(in: .rect(cornerRadius: 10))
            }

            if let desc = approval.description, !desc.isEmpty {
                Text(desc)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.appTextSecondary)
                    .lineLimit(3)
            }

            if !approval.formattedTime.isEmpty {
                Text("Erstellt: \(approval.formattedTime)")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appTextSecondary)
            }

            Divider()
                .background(Color.appBorder)

            // Action Buttons
            if isProcessing {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.appAccent))
                    Text("Wird verarbeitet...")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.appTextSecondary)
                    Spacer()
                }
                .padding(.vertical, 4)
            } else {
                HStack(spacing: 12) {
                    Button {
                        Task { await viewModel.deny(approval) }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                            Text("Ablehnen")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(Color.appError)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .glassEffect(in: .rect(cornerRadius: 12))
                    }

                    Button {
                        Task { await viewModel.approve(approval) }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                            Text("Genehmigen")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(Color.appSuccess)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .glassEffect(in: .rect(cornerRadius: 12))
                    }
                }
            }
        }
        .padding(16)
        .glassEffect(in: .rect(cornerRadius: 16))
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}
