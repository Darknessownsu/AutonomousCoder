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
        }
    }
}

// MARK: - App State

class AppState: ObservableObject {
    @Published var isRunning: Bool = false
    @Published var systemMetrics: SystemMetrics?
    @Published var recentTasks: [TaskSummary] = []
    @Published var logs: [LogEntry] = []
    
    private var commandCenter: AICommandCenter?
    
    func startSystem() async {
        do {
            let configuration = SystemConfiguration()
            let commandCenter = try AICommandCenter(configuration: configuration)
            self.commandCenter = commandCenter
            
            try await commandCenter.start()
            
            await MainActor.run {
                isRunning = true
                addLog("System started successfully", level: .info)
            }
            
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
    
    func addLog(_ message: String, level: LogLevel) {
        let entry = LogEntry(message: message, level: level, timestamp: Date())
        logs.append(entry)
        
        if logs.count > 100 {
            logs.removeFirst(20)
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