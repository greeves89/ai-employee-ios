import Foundation
import SwiftUI

@MainActor
@Observable
final class TasksViewModel {
    var tasks: [AITask] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var filter: TaskFilter = .all

    private var refreshTask: Task<Void, Never>?

    enum TaskFilter: String, CaseIterable {
        case all = "Alle"
        case running = "Laufend"
        case pending = "Ausstehend"
        case completed = "Abgeschlossen"
        case failed = "Fehlgeschlagen"

        func matches(_ task: AITask) -> Bool {
            switch self {
            case .all:
                return true
            case .running:
                return task.isRunning
            case .pending:
                return ["pending", "waiting"].contains(task.status.lowercased())
            case .completed:
                return ["completed", "done"].contains(task.status.lowercased())
            case .failed:
                return ["failed", "error"].contains(task.status.lowercased())
            }
        }
    }

    var filteredTasks: [AITask] {
        tasks.filter { filter.matches($0) }
    }

    var runningCount: Int {
        tasks.filter { $0.isRunning }.count
    }

    var pendingCount: Int {
        tasks.filter { ["pending", "waiting"].contains($0.status.lowercased()) }.count
    }

    // MARK: - Load Tasks

    func loadTasks() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            tasks = try await APIClient.shared.getTasks()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() async {
        await loadTasks()
    }

    // MARK: - Auto Refresh

    func startAutoRefresh() {
        stopAutoRefresh()
        refreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 15_000_000_000)
                await loadTasks()
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }
}
