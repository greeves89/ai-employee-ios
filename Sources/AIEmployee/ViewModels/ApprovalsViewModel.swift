import Foundation
import SwiftUI

@MainActor
final class ApprovalsViewModel: ObservableObject {
    @Published var approvals: [Approval] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var processingIds: Set<String> = []

    var pendingCount: Int {
        approvals.count
    }

    // MARK: - Load Approvals

    func loadApprovals() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            approvals = try await APIClient.shared.getPendingApprovals()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() async {
        await loadApprovals()
    }

    // MARK: - Actions

    func approve(_ approval: Approval) async {
        guard !processingIds.contains(approval.id) else { return }
        processingIds.insert(approval.id)

        do {
            try await APIClient.shared.approveCommand(id: approval.id)
            approvals.removeAll { $0.id == approval.id }
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        processingIds.remove(approval.id)
    }

    func deny(_ approval: Approval) async {
        guard !processingIds.contains(approval.id) else { return }
        processingIds.insert(approval.id)

        do {
            try await APIClient.shared.denyCommand(id: approval.id)
            approvals.removeAll { $0.id == approval.id }
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        processingIds.remove(approval.id)
    }

    func isProcessing(_ approvalId: String) -> Bool {
        processingIds.contains(approvalId)
    }
}
