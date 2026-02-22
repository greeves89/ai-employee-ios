import SwiftUI

struct ApprovalsView: View {
    @ObservedObject var viewModel: ApprovalsViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if viewModel.isLoading && viewModel.approvals.isEmpty {
                    LoadingView(message: "Genehmigungen werden geladen...")
                } else if viewModel.approvals.isEmpty && !viewModel.isLoading {
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(Color.appSuccess.opacity(0.12))
                                .frame(width: 100, height: 100)
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 44))
                                .foregroundColor(Color.appSuccess)
                        }

                        VStack(spacing: 8) {
                            Text("Keine ausstehenden Genehmigungen")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            Text("Alle Aktionen wurden genehmigt.")
                                .font(.system(size: 15))
                                .foregroundColor(Color.appTextSecondary)
                        }
                        .padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Warning Header
                            if !viewModel.approvals.isEmpty {
                                HStack(spacing: 10) {
                                    Image(systemName: "exclamationmark.shield.fill")
                                        .foregroundColor(Color.appWarning)
                                    Text("\(viewModel.approvals.count) Aktion\(viewModel.approvals.count == 1 ? "" : "en") warten auf Ihre Genehmigung")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color.appWarning)
                                    Spacer()
                                }
                                .padding(14)
                                .background(Color.appWarning.opacity(0.1))
                                .overlay(
                                    Rectangle()
                                        .fill(Color.appWarning)
                                        .frame(width: 3),
                                    alignment: .leading
                                )
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

                // Error
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
}

// MARK: - Approval Card

struct ApprovalCard: View {
    let approval: Approval
    @ObservedObject var viewModel: ApprovalsViewModel

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
                        .foregroundColor(Color.appTextSecondary)
                }
                Spacer()

                // Risk Badge
                HStack(spacing: 5) {
                    Image(systemName: approval.riskIcon)
                        .font(.system(size: 11))
                    Text(approval.riskLabel)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(approval.riskColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(approval.riskColor.opacity(0.12))
                .cornerRadius(8)
            }

            // Command (monospace style)
            VStack(alignment: .leading, spacing: 6) {
                Text("Befehl:")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.appTextSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                ScrollView(.horizontal, showsIndicators: false) {
                    Text(approval.command)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(Color(hex: "a5f3fc"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                }
                .background(Color(hex: "0d1526"))
                .cornerRadius(10)
            }

            // Description
            if let desc = approval.description, !desc.isEmpty {
                Text(desc)
                    .font(.system(size: 13))
                    .foregroundColor(Color.appTextSecondary)
                    .lineLimit(3)
            }

            // Time
            if !approval.formattedTime.isEmpty {
                Text("Erstellt: \(approval.formattedTime)")
                    .font(.system(size: 12))
                    .foregroundColor(Color.appTextSecondary)
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
                        .foregroundColor(Color.appTextSecondary)
                    Spacer()
                }
                .padding(.vertical, 4)
            } else {
                HStack(spacing: 12) {
                    // Deny Button
                    Button {
                        Task { await viewModel.deny(approval) }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                            Text("Ablehnen")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(Color.appError)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.appError.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.appError.opacity(0.3), lineWidth: 1)
                        )
                    }

                    // Approve Button
                    Button {
                        Task { await viewModel.approve(approval) }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                            Text("Genehmigen")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(Color.appSuccess)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.appSuccess.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.appSuccess.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(Color.appCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(approval.riskColor.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}
