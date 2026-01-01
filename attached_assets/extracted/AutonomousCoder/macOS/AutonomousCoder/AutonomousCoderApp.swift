//
//  AutonomousCoderApp.swift
//  AutonomousCoder
//
//  Created by Autonomous Coder on 2025-01-01
//  Copyright (c) 2025 Autonomous Coder. All rights reserved.
//

import SwiftUI

@main
struct AutonomousCoderApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 1200, minHeight: 800)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        
        MenuBarExtra("Autonomous Coder", systemImage: "cpu") {
            MenuBarView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.window)
        
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}

// MARK: - App State

class AppState: ObservableObject {
    @Published var isRunning: Bool = false
    @Published var systemMetrics: SystemMetrics?
    @Published var recentTasks: [TaskSummary] = []
    @Published var configuration: SystemConfiguration
    @Published var logs: [LogEntry] = []
    
    private var commandCenter: AICommandCenter?
    private var monitoringTask: Task<Void, Never>?
    
    init() {
        self.configuration = SystemConfiguration()
        loadConfiguration()
    }
    
    func startSystem() async {
        do {
            let commandCenter = try AICommandCenter(configuration: configuration)
            self.commandCenter = commandCenter
            
            try await commandCenter.start()
            
            await MainActor.run {
                isRunning = true
                addLog("System started successfully", level: .info)
            }
            
            startMonitoring()
            
        } catch {
            await MainActor.run {
                addLog("Failed to start system: \(error.localizedDescription)", level: .error)
            }
        }
    }
    
    func stopSystem() async {
        do {
            try await commandCenter?.stop()
            
            await MainActor.run {
                isRunning = false
                monitoringTask?.cancel()
                addLog("System stopped", level: .info)
            }
            
        } catch {
            await MainActor.run {
                addLog("Error stopping system: \(error.localizedDescription)", level: .error)
            }
        }
    }
    
    func submitTask(_ task: CodingTask) async {
        do {
            let taskID = try await commandCenter?.submitTask(task)
            await MainActor.run {
                addLog("Task submitted: \(task.title) (ID: \(taskID?.value ?? "unknown"))", level: .info)
            }
        } catch {
            await MainActor.run {
                addLog("Failed to submit task: \(error.localizedDescription)", level: .error)
            }
        }
    }
    
    private func startMonitoring() {
        monitoringTask = Task {
            while !Task.isCancelled {
                do {
                    if let metrics = await commandCenter?.getSystemMetrics() {
                        await MainActor.run {
                            systemMetrics = metrics
                        }
                    }
                    
                    try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                    
                } catch {
                    await MainActor.run {
                        addLog("Monitoring error: \(error.localizedDescription)", level: .error)
                    }
                }
            }
        }
    }
    
    private func loadConfiguration() {
        do {
            let configManager = try ConfigurationManager()
            configuration = configManager.getConfiguration()
            addLog("Configuration loaded", level: .info)
        } catch {
            addLog("Using default configuration: \(error.localizedDescription)", level: .warning)
        }
    }
    
    func addLog(_ message: String, level: LogLevel) {
        let entry = LogEntry(message: message, level: level, timestamp: Date())
        logs.append(entry)
        
        if logs.count > 1000 {
            logs.removeFirst(100)
        }
    }
}

struct LogEntry: Identifiable {
    let id = UUID()
    let message: String
    let level: LogLevel
    let timestamp: Date
}

struct TaskSummary: Identifiable {
    let id: EntityID
    let title: String
    let status: TaskStatus
    let language: ProgrammingLanguage
    let submittedAt: Date
}