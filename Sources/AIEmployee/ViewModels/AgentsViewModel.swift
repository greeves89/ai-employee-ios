import Foundation
import SwiftUI

@MainActor
@Observable
final class AgentsViewModel {
    var agents: [Agent] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var actionInProgress: Set<String> = []

    private var pollingTask: Task<Void, Never>?
    private let pollingInterval: UInt64 = 10_000_000_000 // 10 seconds

    init() {}

    // MARK: - Load Agents

    func loadAgents() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            agents = try await APIClient.shared.getAgents()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() async {
        await loadAgents()
    }

    // MARK: - Polling

    func startPolling() {
        stopPolling()
        pollingTask = Task {
            while !Task.isCancelled {
                await loadAgents()
                try? await Task.sleep(nanoseconds: pollingInterval)
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    // MARK: - Agent Control

    func startAgent(_ agent: Agent) async {
        guard !actionInProgress.contains(agent.id) else { return }
        actionInProgress.insert(agent.id)

        do {
            try await APIClient.shared.startAgent(id: agent.id)
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await loadAgents()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        actionInProgress.remove(agent.id)
    }

    func stopAgent(_ agent: Agent) async {
        guard !actionInProgress.contains(agent.id) else { return }
        actionInProgress.insert(agent.id)

        do {
            try await APIClient.shared.stopAgent(id: agent.id)
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await loadAgents()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        actionInProgress.remove(agent.id)
    }

    func restartAgent(_ agent: Agent) async {
        guard !actionInProgress.contains(agent.id) else { return }
        actionInProgress.insert(agent.id)

        do {
            try await APIClient.shared.restartAgent(id: agent.id)
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await loadAgents()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        actionInProgress.remove(agent.id)
    }

    func isActionInProgress(for agentId: String) -> Bool {
        actionInProgress.contains(agentId)
    }

    // MARK: - Computed

    var runningCount: Int {
        agents.filter { $0.isRunning }.count
    }

    var stoppedCount: Int {
        agents.filter { $0.isStopped }.count
    }
}
