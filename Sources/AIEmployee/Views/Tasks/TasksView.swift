import SwiftUI

struct TasksView: View {
    @ObservedObject var viewModel: TasksViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Filter Bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(TasksViewModel.TaskFilter.allCases, id: \.self) { filter in
                                FilterChip(
                                    label: filter.rawValue,
                                    isSelected: viewModel.filter == filter
                                ) {
                                    viewModel.filter = filter
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .background(Color.appBackground)

                    Divider()
                        .background(Color.appBorder)

                    // Content
                    if viewModel.isLoading && viewModel.tasks.isEmpty {
                        Spacer()
                        LoadingView(message: "Aufgaben werden geladen...")
                        Spacer()
                    } else if viewModel.filteredTasks.isEmpty {
                        Spacer()
                        EmptyStateView(
                            icon: "list.bullet.clipboard",
                            title: "Keine Aufgaben",
                            message: viewModel.filter == .all
                                ? "Es gibt derzeit keine Aufgaben."
                                : "Keine Aufgaben in dieser Kategorie."
                        )
                        Spacer()
                    } else {
                        ScrollView {
                            // Stats
                            if viewModel.filter == .all {
                                HStack(spacing: 12) {
                                    if viewModel.runningCount > 0 {
                                        StatCard(
                                            value: "\(viewModel.runningCount)",
                                            label: "Laufend",
                                            color: Color.appAccent,
                                            icon: "arrow.clockwise.circle.fill"
                                        )
                                    }
                                    if viewModel.pendingCount > 0 {
                                        StatCard(
                                            value: "\(viewModel.pendingCount)",
                                            label: "Ausstehend",
                                            color: Color.appTextSecondary,
                                            icon: "clock.fill"
                                        )
                                    }
                                    StatCard(
                                        value: "\(viewModel.tasks.count)",
                                        label: "Gesamt",
                                        color: Color.appAccent,
                                        icon: "list.bullet"
                                    )
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                            }

                            LazyVStack(spacing: 10) {
                                ForEach(viewModel.filteredTasks) { task in
                                    TaskCard(task: task)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .refreshable {
                            await viewModel.refresh()
                        }
                    }
                }
            }
            .navigationTitle("Aufgaben")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadTasks()
                viewModel.startAutoRefresh()
            }
            .onDisappear {
                viewModel.stopAutoRefresh()
            }
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : Color.appTextSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.appAccent : Color.appCard)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ? Color.appAccent : Color.appBorder,
                            lineWidth: 1
                        )
                )
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Task Card

struct TaskCard: View {
    let task: AITask
    @State private var rotationAngle: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Status Icon
                ZStack {
                    Circle()
                        .fill(task.statusColor.opacity(0.15))
                        .frame(width: 38, height: 38)

                    Image(systemName: task.statusIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(task.statusColor)
                        .rotationEffect(.degrees(task.isRunning ? rotationAngle : 0))
                        .onAppear {
                            if task.isRunning {
                                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                                    rotationAngle = 360
                                }
                            }
                        }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(task.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(2)

                        Spacer()

                        // Status Badge
                        Text(task.statusLabel)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(task.statusColor)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(task.statusColor.opacity(0.12))
                            .cornerRadius(8)
                    }

                    // Meta info
                    HStack(spacing: 12) {
                        if let agentName = task.agentName {
                            Label(agentName, systemImage: "cpu")
                                .font(.system(size: 12))
                                .foregroundColor(Color.appTextSecondary)
                        }

                        if let time = task.formattedCreatedAt {
                            Label(time, systemImage: "clock")
                                .font(.system(size: 12))
                                .foregroundColor(Color.appTextSecondary)
                        }
                    }
                }
            }

            // Running Progress Indicator
            if task.isRunning {
                ProgressIndicatorBar()
            }

            // Output Preview
            if let output = task.output, !output.isEmpty {
                Text(output)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color.appTextSecondary)
                    .lineLimit(3)
                    .padding(10)
                    .background(Color(hex: "0d1526"))
                    .cornerRadius(8)
            }
        }
        .padding(14)
        .background(Color.appCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    task.isRunning ? Color.appAccent.opacity(0.3) : Color.appBorder,
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Progress Indicator Bar

struct ProgressIndicatorBar: View {
    @State private var progress: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.appAccent.opacity(0.2))
                    .frame(height: 3)

                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.appAccent)
                    .frame(width: geometry.size.width * 0.3, height: 3)
                    .offset(x: progress * geometry.size.width)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: progress
                    )
            }
        }
        .frame(height: 3)
        .onAppear {
            progress = 0.7
        }
    }
}
