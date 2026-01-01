//
//  main.swift
//  AutonomousCoderCLI
//
//  Created by Autonomous Coder on 2025-01-01
//  Copyright (c) 2025 Autonomous Coder. All rights reserved.
//

import Foundation
import Logging
import ServiceLifecycle

// MARK: - Main Entry Point

@main
struct AutonomousCoderCLI {
    static func main() async throws {
        let logger = Logger(label: "AutonomousCoderCLI")
        
        logger.info("Starting Autonomous Coder CLI")
        
        let arguments = CommandLine.arguments
        
        if arguments.count < 2 {
            printUsage()
            return
        }
        
        let command = arguments[1]
        
        switch command {
        case "start":
            try await startSystem()
            
        case "task":
            try await handleTaskCommand(Array(arguments.dropFirst(2)))
            
        case "status":
            try await showStatus()
            
        case "config":
            try await handleConfigCommand(Array(arguments.dropFirst(2)))
            
        case "monitor":
            try await startMonitoring()
            
        case "help", "-h", "--help":
            printUsage()
            
        default:
            print("Unknown command: \(command)")
            printUsage()
        }
    }
    
    private static func startSystem() async throws {
        print("🚀 Starting Autonomous Coder System...")
        
        let configuration = try loadConfiguration()
        let commandCenter = AICommandCenter(configuration: configuration)
        
        let serviceLifecycle = ServiceLifecycle()
        serviceLifecycle.register(commandCenter)
        
        try await serviceLifecycle.start()
        
        print("✅ Autonomous Coder System started successfully")
        print("📊 Dashboard available at: http://localhost:8080")
        print("🛑 Press Ctrl+C to stop")
        
        try await serviceLifecycle.wait()
    }
    
    private static func handleTaskCommand(_ arguments: [String]) async throws {
        guard !arguments.isEmpty else {
            print("Task command requires an action: submit, status, list")
            return
        }
        
        let action = arguments[0]
        
        switch action {
        case "submit":
            try await submitTask(Array(arguments.dropFirst(1)))
            
        case "status":
            guard arguments.count > 1 else {
                print("Task status requires a task ID")
                return
            }
            let taskID = arguments[1]
            try await showTaskStatus(taskID)
            
        case "list":
            try await listTasks()
            
        default:
            print("Unknown task action: \(action)")
        }
    }
    
    private static func submitTask(_ arguments: [String]) async throws {
        guard arguments.count >= 2 else {
            print("Task submit requires title and description")
            return
        }
        
        let title = arguments[0]
        let description = arguments[1]
        let language = arguments.count > 2 ? arguments[2] : "swift"
        
        let task = CodingTask(
            title: title,
            description: description,
            targetLanguage: ProgrammingLanguage(rawValue: language) ?? .swift
        )
        
        let configuration = try loadConfiguration()
        let commandCenter = AICommandCenter(configuration: configuration)
        
        let taskID = try await commandCenter.submitTask(task)
        
        print("✅ Task submitted successfully")
        print("📋 Task ID: \(taskID.value)")
        print("📝 Title: \(title)")
        print("💻 Language: \(language)")
    }
    
    private static func showTaskStatus(_ taskID: String) async throws {
        let configuration = try loadConfiguration()
        let commandCenter = AICommandCenter(configuration: configuration)
        
        let status = try await commandCenter.getTaskStatus(EntityID(taskID))
        let result = try await commandCenter.getTaskResult(EntityID(taskID))
        
        print("📊 Task Status: \(status.rawValue)")
        
        if let result = result {
            switch result {
            case .codeFile(let codeFile):
                print("📄 Generated Code:")
                print("```\(codeFile.language.rawValue)")
                print(codeFile.content)
                print("```")
                
            case .error(let error):
                print("❌ Error: \(error)")
            }
        }
    }
    
    private static func listTasks() async throws {
        print("📋 Recent Tasks:")
        print("(Task listing functionality would be implemented here)")
    }
    
    private static func showStatus() async throws {
        let configuration = try loadConfiguration()
        let commandCenter = AICommandCenter(configuration: configuration)
        
        let metrics = await commandCenter.getSystemMetrics()
        
        print("🏗️  Autonomous Coder System Status")
        print("=====================================")
        print("⏱️  Uptime: \(formatTimeInterval(metrics.uptime))")
        print("📊 Tasks Processed: \(metrics.tasksProcessed)")
        print("🔄 Tasks In Queue: \(metrics.tasksInQueue)")
        print("🤖 Active Agents: \(metrics.activeAgents)")
        print("⚡ Avg Task Time: \(formatTimeInterval(metrics.averageTaskTime))")
        print("📈 Improvement Success Rate: \(String(format: "%.1f%%", metrics.improvementSuccessRate * 100))")
    }
    
    private static func handleConfigCommand(_ arguments: [String]) async throws {
        guard !arguments.isEmpty else {
            print("Config command requires an action: show, set")
            return
        }
        
        let action = arguments[0]
        
        switch action {
        case "show":
            try await showConfiguration()
            
        case "set":
            guard arguments.count >= 3 else {
                print("Config set requires key and value")
                return
            }
            let key = arguments[1]
            let value = arguments[2]
            try await setConfiguration(key: key, value: value)
            
        default:
            print("Unknown config action: \(action)")
        }
    }
    
    private static func showConfiguration() async throws {
        let configuration = try loadConfiguration()
        
        print("⚙️  System Configuration")
        print("======================")
        print("📝 Max Code Generation Time: \(configuration.maxCodeGenerationTime)s")
        print("⏱️  Max Execution Time: \(configuration.maxExecutionTime)s")
        print("💾 Max Memory Usage: \(formatBytes(configuration.maxMemoryUsage))")
        print("🔒 Sandbox Enabled: \(configuration.sandboxEnabled)")
        print("🧠 Self-Improvement Enabled: \(configuration.selfImprovementEnabled)")
        print("👤 Human-in-the-Loop: \(configuration.humanInTheLoop)")
        print("📊 Logging Level: \(configuration.loggingLevel.rawValue)")
    }
    
    private static func setConfiguration(key: String, value: String) async throws {
        print("Setting configuration \(key) = \(value)")
        print("(Configuration updates would be implemented here)")
    }
    
    private static func startMonitoring() async throws {
        print("📊 Starting real-time monitoring...")
        print("📈 Press Ctrl+C to stop")
        
        let configuration = try loadConfiguration()
        let monitoringSystem = EnhancedMonitoringSystem(configuration: configuration)
        
        try await monitoringSystem.start()
        
        while true {
            let dashboardData = await monitoringSystem.getDashboardData()
            
            clearScreen()
            printMonitoringDashboard(dashboardData)
            
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        }
    }
    
    private static func printUsage() {
        print("""
        🚀 Autonomous Coder CLI
        
        Usage: autonomous-coder <command> [options]
        
        Commands:
          start                    Start the Autonomous Coder system
          task submit <title> <desc> [lang]  Submit a new coding task
          task status <id>         Get status of a specific task
          task list                List recent tasks
          status                   Show system status
          monitor                  Start real-time monitoring dashboard
          config show              Show current configuration
          config set <key> <value> Set configuration value
          help                     Show this help message
        
        Examples:
          autonomous-coder start
          autonomous-coder task submit "Sort Array" "Implement quicksort algorithm" python
          autonomous-coder task status 123e4567-e89b-12d3-a456-426614174000
          autonomous-coder monitor
        
        For more information, visit: https://github.com/autonomous-coder/project
        """)
    }
    
    private static func loadConfiguration() throws -> SystemConfiguration {
        return try ConfigurationManager().getConfiguration()
    }
    
    private static func formatTimeInterval(_ interval: TimeInterval) -> String {
        if interval < 60 {
            return String(format: "%.1fs", interval)
        } else if interval < 3600 {
            return String(format: "%.1fm", interval / 60)
        } else {
            return String(format: "%.1fh", interval / 3600)
        }
    }
    
    private static func formatBytes(_ bytes: UInt64) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var value = Double(bytes)
        var unitIndex = 0
        
        while value >= 1024 && unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }
        
        return String(format: "%.2f %@", value, units[unitIndex])
    }
    
    private static func clearScreen() {
        print("\u{001B}[2J\u{001B}[H", terminator: "")
    }
    
    private static func printMonitoringDashboard(_ data: DashboardData) {
        print("""
        📊 Autonomous Coder - Real-time Monitoring
        =============================================
        
        🖥️  System Resources
        -------------------
        CPU Usage:  \(String(format: "%.1f%%", data.cpuUsage))
        Memory:     \(String(format: "%.2f GB", data.memoryUsage))
        Uptime:     \(formatTimeInterval(data.systemUptime))
        
        📈 Performance Metrics
        ---------------------
        Active Tasks: \(data.activeTasks)
        Completed:    \(data.completedTasks)
        Error Rate:   \(String(format: "%.1f%%", data.errorRate * 100))
        Avg Response: \(formatTimeInterval(data.averageResponseTime))
        
        🔄 Real-time Updates
        -------------------
        Last Updated: \(Date())
        
        Press Ctrl+C to stop monitoring
        """)
    }
}

// MARK: - Extensions for CLI

extension TaskResult {
    var codeFile: CodeFile? {
        if case .codeFile(let file) = self {
            return file
        }
        return nil
    }
    
    var error: Error? {
        if case .error(let err) = self {
            return err
        }
        return nil
    }
}