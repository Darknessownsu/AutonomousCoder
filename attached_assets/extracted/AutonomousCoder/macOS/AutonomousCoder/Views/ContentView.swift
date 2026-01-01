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
    @State private var selectedTab: Tab = .dashboard
    
    enum Tab {
        case dashboard
        case tasks
        case agents
        case monitoring
        , logs
    }
    
    var body: some View {
        NavigationSplitView {
            Sidebar(selection: $selectedTab)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250)
        } detail: {
            DetailView(selectedTab: selectedTab)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ControlButton()
            }
        }
    }
}

// MARK: - Sidebar

struct Sidebar: View {
    @Binding var selection: ContentView.Tab
    
    var body: some View {
        List(selection: $selection) {
            Section("System") {
                Label("Dashboard", systemImage: "chart.bar.fill")
                    .tag(ContentView.Tab.dashboard)
                
                Label("Tasks", systemImage: "list.bullet.rectangle")
                    .tag(ContentView.Tab.tasks)
                
                Label("Agents", systemImage: "cpu.fill")
                    .tag(ContentView.Tab.agents)
                
                Label("Monitoring", systemImage: "chart.line.uptrend.xyaxis")
                    .tag(ContentView.Tab.monitoring)
            }
            
            Section("Logs & Debug") {
                Label("System Logs", systemImage: "doc.text.fill")
                    .tag(ContentView.Tab.logs)
            }
        }
        .listStyle(.sidebar)
        .scrollDisabled(true)
    }
}

// MARK: - Detail Views

struct DetailView: View {
    let selectedTab: ContentView.Tab
    
    var body: some View {
        switch selectedTab {
        case .dashboard:
            DashboardView()
                .navigationTitle("Dashboard")
        case .tasks:
            TasksView()
                .navigationTitle("Tasks")
        case .agents:
            AgentsView()
                .navigationTitle("Agents")
        case .monitoring:
            MonitoringView()
                .navigationTitle("Monitoring")
        case .logs:
            LogsView()
                .navigationTitle("System Logs")
        }
    }
}

// MARK: - Dashboard View

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                StatusCard()
                
                MetricsGrid()
                
                RecentTasksCard()
                
                Spacer()
            }
            .padding()
        }
    }
}

struct StatusCard: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
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
                
                if let uptime = appState.systemMetrics?.uptime {
                    Text("Uptime: \(formatTimeInterval(uptime))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if appState.isRunning {
                Button(action: {
                    Task { await appState.stopSystem() }
                }) {
                    Label("Stop", systemImage: "stop.fill")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            } else {
                Button(action: {
                    Task { await appState.startSystem() }
                }) {
                    Label("Start", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct MetricsGrid: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
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
                title: "Avg Task Time",
                value: formatTimeInterval(appState.systemMetrics?.averageTaskTime ?? 0),
                systemImage: "timer",
                color: .purple
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title)
                .bold()
                .foregroundColor(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct RecentTasksCard: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Tasks")
                .font(.title2)
                .bold()
            
            if appState.recentTasks.isEmpty {
                Text("No tasks yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(appState.recentTasks) { task in
                    TaskRow(task: task)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct TaskRow: View {
    let task: TaskSummary
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                
                HStack {
                    Text(task.language.rawValue.uppercased())
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                    
                    Text(task.status.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(task.status.color)
                }
            }
            
            Spacer()
            
            Text(task.submittedAt, style: .time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Tasks View

struct TasksView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingTaskCreator = false
    
    var body: some View {
        VStack {
            HStack {
                Text("Manage Coding Tasks")
                    .font(.title2)
                    .bold()
                
                Spacer()
                
                Button(action: {
                    showingTaskCreator = true
                }) {
                    Label("New Task", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            if appState.recentTasks.isEmpty {
                EmptyStateView(
                    title: "No Tasks Yet",
                    message: "Create your first coding task to get started",
                    systemImage: "doc.badge.plus"
                )
            } else {
                List(appState.recentTasks) { task in
                    TaskRow(task: task)
                        .padding(.vertical, 8)
                }
                .listStyle(.plain)
            }
        }
        .sheet(isPresented: $showingTaskCreator) {
            TaskCreatorView()
        }
    }
}

// MARK: - Agents View

struct AgentsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack {
            Text("AI Agents")
                .font(.title2)
                .bold()
                .padding()
            
            if appState.isRunning {
                Text("\(appState.systemMetrics?.activeAgents ?? 0) agents active")
                    .foregroundColor(.secondary)
                
                // Agent details would be shown here
                Spacer()
            } else {
                EmptyStateView(
                    title: "System Not Running",
                    message: "Start the system to see active agents",
                    systemImage: "cpu"
                )
            }
        }
    }
}

// MARK: - Monitoring View

struct MonitoringView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack {
            Text("System Monitoring")
                .font(.title2)
                .bold()
                .padding()
            
            if let metrics = appState.systemMetrics {
                MetricsChart(metrics: metrics)
                    .frame(height: 300)
                    .padding()
                
                DetailedMetricsView(metrics: metrics)
            } else {
                EmptyStateView(
                    title: "No Metrics Available",
                    message: "Start the system to see monitoring data",
                    systemImage: "chart.line.uptrend.xyaxis"
                )
            }
        }
    }
}

struct MetricsChart: View {
    let metrics: SystemMetrics
    
    var body: some View {
        // In a real implementation, this would show interactive charts
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.1))
            .overlay(
                Text("Performance Charts")
                    .foregroundColor(.secondary)
            )
    }
}

struct DetailedMetricsView: View {
    let metrics: SystemMetrics
    
    var body: some View {
        Grid(alignment: .leading) {
            GridRow {
                Text("Tasks Processed:")
                Text("\(metrics.tasksProcessed)")
            }
            
            GridRow {
                Text("Tasks in Queue:")
                Text("\(metrics.tasksInQueue)")
            }
            
            GridRow {
                Text("Average Task Time:")
                Text(formatTimeInterval(metrics.averageTaskTime))
            }
            
            GridRow {
                Text("Improvement Success Rate:")
                Text(String(format: "%.1f%%", metrics.improvementSuccessRate * 100))
            }
        }
        .padding()
    }
}

// MARK: - Logs View

struct LogsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack {
            HStack {
                Text("System Logs")
                    .font(.title2)
                    .bold()
                
                Spacer()
                
                Button(action: {
                    appState.logs.removeAll()
                }) {
                    Label("Clear", systemImage: "trash")
                }
                .buttonStyle(.bordered)
            }
            .padding()
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(appState.logs) { entry in
                            LogEntryView(entry: entry)
                        }
                    }
                    .padding()
                }
                .onChange(of: appState.logs.count) { _ in
                    if let last = appState.logs.last {
                        proxy.scrollTo(last.id)
                    }
                }
            }
        }
    }
}

struct LogEntryView: View {
    let entry: LogEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(entry.level.color)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.message)
                    .font(.system(size: 12, design: .monospace))
                
                Text(entry.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Supporting Views

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title2)
                .bold()
            
            Text(message)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ControlButton: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        if appState.isRunning {
            Button(action: {
                Task { await appState.stopSystem() }
            }) {
                Image(systemName: "stop.fill")
            }
            .help("Stop System")
        } else {
            Button(action: {
                Task { await appState.startSystem() }
            }) {
                Image(systemName: "play.fill")
            }
            .help("Start System")
        }
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