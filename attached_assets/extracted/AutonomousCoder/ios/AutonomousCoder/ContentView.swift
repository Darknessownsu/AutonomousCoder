//
//  ContentView.swift
//  AutonomousCoder
//
//  Created by Autonomous Coder on 2025-01-01
//  Copyright (c) 2025 Autonomous Coder. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(0)
            
            TasksView()
                .tabItem {
                    Label("Tasks", systemImage: "list.bullet.rectangle")
                }
                .tag(1)
            
            MonitoringView()
                .tabItem {
                    Label("Monitor", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)
            
            LogsView()
                .tabItem {
                    Label("Logs", systemImage: "doc.text.fill")
                }
                .tag(3)
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Dashboard View

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    StatusCard()
                    
                    MetricsGrid()
                    
                    QuickActionsCard()
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct StatusCard: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("System Status")
                        .font(.title2)
                        .bold()
                    
                    HStack {
                        Circle()
                            .fill(appState.isRunning ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        
                        Text(appState.isRunning ? "Running" : "Stopped")
                            .font(.headline)
                            .foregroundColor(appState.isRunning ? .green : .red)
                    }
                }
                
                Spacer()
            }
            
            Button(action: {
                if appState.isRunning {
                    Task { await appState.stopSystem() }
                } else {
                    Task { await appState.startSystem() }
                }
            }) {
                Text(appState.isRunning ? "Stop System" : "Start System")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(appState.isRunning ? .red : .blue)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct MetricsGrid: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            MetricCard(
                title: "Tasks Processed",
                value: "\(appState.systemMetrics?.tasksProcessed ?? 0)",
                systemImage: "checkmark.circle.fill",
                color: .green
            )
            
            MetricCard(
                title: "Tasks in Queue",
                value: "\(appState.systemMetrics?.tasksInQueue ?? 0)",
                systemImage: "clock.fill",
                color: .orange
            )
            
            MetricCard(
                title: "Active Agents",
                value: "\(appState.systemMetrics?.activeAgents ?? 0)",
                systemImage: "cpu.fill",
                color: .blue
            )
            
            MetricCard(
                title: "Improvement Rate",
                value: String(format: "%.1f%%", (appState.systemMetrics?.improvementSuccessRate ?? 0) * 100),
                systemImage: "chart.line.uptrend.xyaxis",
                color: .indigo
            )
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .bold()
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct QuickActionsCard: View {
    @State private var showingTaskCreator = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.title2)
                .bold()
            
            Button(action: {
                showingTaskCreator = true
            }) {
                Label("Create Task", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .sheet(isPresented: $showingTaskCreator) {
                TaskCreatorView()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

// MARK: - Tasks View

struct TasksView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingTaskCreator = false
    
    var body: some View {
        NavigationView {
            List {
                if appState.recentTasks.isEmpty {
                    Section {
                        Text("No tasks yet")
                            .foregroundColor(.secondary)
                    }
                } else {
                    ForEach(appState.recentTasks) { task in
                        TaskRow(task: task)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showingTaskCreator = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingTaskCreator) {
                TaskCreatorView()
            }
        }
    }
}

struct TaskRow: View {
    let task: TaskSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(task.title)
                .font(.headline)
            
            HStack {
                Text(task.language.rawValue.uppercased())
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
                
                Spacer()
                
                Text(task.status.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(task.status.color)
            }
            
            Text(task.submittedAt, style: .time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Task Creator View

struct TaskCreatorView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedLanguage = ProgrammingLanguage.swift
    @State private var difficulty = DifficultyLevel.medium
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Task Title", text: $title)
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Configuration") {
                    Picker("Language", selection: $selectedLanguage) {
                        ForEach(ProgrammingLanguage.allCases, id: \\.self) { language in
                            Text(language.description).tag(language)
                        }
                    }
                    
                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(DifficultyLevel.allCases, id: \\.self) { level in
                            Text(level.rawValue.capitalized).tag(level)
                        }
                    }
                }
            }
            .navigationTitle("Create Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        submitTask()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !title.isEmpty && !description.isEmpty
    }
    
    private func submitTask() {
        let task = CodingTask(
            title: title,
            description: description,
            targetLanguage: selectedLanguage,
            difficulty: difficulty
        )
        
        Task {
            await appState.submitTask(task)
            await MainActor.run {
                dismiss()
            }
        }
    }
}

// MARK: - Monitoring View

struct MonitoringView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let metrics = appState.systemMetrics {
                        PerformanceMetricsCard(metrics: metrics)
                        
                        SystemMetricsCard(metrics: metrics)
                        
                        ImprovementMetricsCard(metrics: metrics)
                    } else {
                        Text("No monitoring data available")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Monitoring")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                // Refresh metrics
            }
        }
    }
}

struct PerformanceMetricsCard: View {
    let metrics: SystemMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Metrics")
                .font(.title2)
                .bold()
            
            Grid(alignment: .leading) {
                GridRow {
                    Text("Average Task Time:")
                    Text(formatTimeInterval(metrics.averageTaskTime))
                }
                
                GridRow {
                    Text("Tasks Processed:")
                    Text("\(metrics.tasksProcessed)")
                }
                
                GridRow {
                    Text("Tasks in Queue:")
                    Text("\(metrics.tasksInQueue)")
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct SystemMetricsCard: View {
    let metrics: SystemMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("System Metrics")
                .font(.title2)
                .bold()
            
            Grid(alignment: .leading) {
                GridRow {
                    Text("Uptime:")
                    Text(formatTimeInterval(metrics.uptime))
                }
                
                GridRow {
                    Text("Active Agents:")
                    Text("\(metrics.activeAgents)")
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct ImprovementMetricsCard: View {
    let metrics: SystemMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Self-Improvement")
                .font(.title2)
                .bold()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Success Rate:")
                
                ProgressView(value: metrics.improvementSuccessRate) {
                    Text(String(format: "%.1f%%", metrics.improvementSuccessRate * 100))
                }
                .tint(.green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

// MARK: - Logs View

struct LogsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            List {
                ForEach(appState.logs) { entry in
                    LogEntryRow(entry: entry)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Logs")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        appState.logs.removeAll()
                    }) {
                        Image(systemName: "trash")
                    }
                }
            }
        }
    }
}

struct LogEntryRow: View {
    let entry: LogEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(entry.level.color)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.message)
                    .font(.system(size: 14, design: .monospace))
                
                Text(entry.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Extensions

extension TaskStatus {
    var color: Color {
        switch self {
        case .pending:
            return .orange
        case .inProgress:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        case .cancelled:
            return .gray
        case .notFound:
            return .secondary
        }
    }
}

extension LogLevel {
    var color: Color {
        switch self {
        case .trace:
            return .gray
        case .debug:
            return .purple
        case .info:
            return .blue
        case .notice:
            return .green
        case .warning:
            return .orange
        case .error:
            return .red
        case .critical:
            return .red
        }
    }
}

func formatTimeInterval(_ interval: TimeInterval) -> String {
    if interval < 1 {
        return String(format: "%.0fms", interval * 1000)
    } else if interval < 60 {
        return String(format: "%.1fs", interval)
    } else if interval < 3600 {
        return String(format: "%.1fm", interval / 60)
    } else {
        return String(format: "%.1fh", interval / 3600)
    }
}