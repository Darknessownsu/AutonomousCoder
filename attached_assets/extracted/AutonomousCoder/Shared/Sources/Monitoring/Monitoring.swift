//
//  Monitoring.swift
//  AutonomousCoder
//
//  Created by Autonomous Coder on 2025-01-01
//  Copyright (c) 2025 Autonomous Coder. All rights reserved.
//

import Foundation
import Logging

// MARK: - Enhanced Monitoring System

/// Comprehensive monitoring and observability system
public actor EnhancedMonitoringSystem: MonitoringSystem {
    private let logger: Logger
    private let configuration: SystemConfiguration
    private let storage: MetricsStorage
    private let alertManager: AlertManager
    private let dashboard: Dashboard
    private let metricsCollector: MetricsCollector
    
    public init(configuration: SystemConfiguration) {
        self.configuration = configuration
        self.logger = configuration.makeLogger(label: "EnhancedMonitoringSystem")
        self.storage = MetricsStorage()
        self.alertManager = AlertManager(configuration: configuration)
        self.dashboard = Dashboard()
        self.metricsCollector = MetricsCollector()
    }
    
    public func start() async throws {
        logger.info("Starting enhanced monitoring system")
        
        try await alertManager.start()
        try await dashboard.start()
        try await metricsCollector.start()
        
        logger.info("Enhanced monitoring system started")
    }
    
    public func stop() async throws {
        logger.info("Stopping enhanced monitoring system")
        
        try await metricsCollector.stop()
        try await dashboard.stop()
        try await alertManager.stop()
        
        logger.info("Enhanced monitoring system stopped")
    }
    
    public func recordMetric(_ name: String, value: Double, tags: [String: String]) async {
        let metric = MetricData(
            name: name,
            value: value,
            timestamp: Timestamp(),
            tags: tags
        )
        
        await storage.store(metric)
        await alertManager.checkAlerts(for: metric)
        
        logger.debug("Recorded metric: \(name) = \(value)")
    }
    
    public func recordEvent(_ name: String, properties: [String: String]) async {
        let event = EventData(
            name: name,
            timestamp: Timestamp(),
            properties: properties
        )
        
        await storage.store(event)
        
        logger.debug("Recorded event: \(name)")
    }
    
    public func getMetrics(for timeRange: TimeRange) async throws -> [MetricData] {
        return await storage.getMetrics(for: timeRange)
    }
    
    public func getEvents(for timeRange: TimeRange) async throws -> [EventData] {
        return await storage.getEvents(for: timeRange)
    }
    
    public func getDashboardData() async -> DashboardData {
        return await dashboard.getCurrentData()
    }
    
    public func createAlert(_ alert: AlertConfiguration) async {
        await alertManager.addAlert(alert)
    }
    
    public func getActiveAlerts() async -> [Alert] {
        return await alertManager.getActiveAlerts()
    }
}

// MARK: - Metrics Storage

/// Storage layer for metrics and events
actor MetricsStorage {
    private var metrics: [MetricData] = []
    private var events: [EventData] = []
    private let maxMetricsCount = 100_000
    private let maxEventsCount = 10_000
    
    func store(_ metric: MetricData) {
        metrics.append(metric)
        
        if metrics.count > maxMetricsCount {
            metrics.removeFirst(metrics.count - maxMetricsCount)
        }
    }
    
    func store(_ event: EventData) {
        events.append(event)
        
        if events.count > maxEventsCount {
            events.removeFirst(events.count - maxEventsCount)
        }
    }
    
    func getMetrics(for timeRange: TimeRange) -> [MetricData] {
        return metrics.filter { metric in
            let metricDate = Date(timeIntervalSince1970: Double(metric.timestamp.nanoseconds) / 1_000_000_000)
            return timeRange.start <= metricDate && metricDate <= timeRange.end
        }
    }
    
    func getEvents(for timeRange: TimeRange) -> [EventData] {
        return events.filter { event in
            let eventDate = Date(timeIntervalSince1970: Double(event.timestamp.nanoseconds) / 1_000_000_000)
            return timeRange.start <= eventDate && eventDate <= timeRange.end
        }
    }
    
    func getLatestMetrics(_ count: Int) -> [MetricData] {
        return Array(metrics.suffix(count))
    }
    
    func getLatestEvents(_ count: Int) -> [EventData] {
        return Array(events.suffix(count))
    }
}

// MARK: - Alert Manager

/// Manages alerts and notifications
actor AlertManager {
    private let logger: Logger
    private let configuration: SystemConfiguration
    private var alerts: [AlertConfiguration] = []
    private var activeAlerts: [Alert] = []
    private let notificationChannel: NotificationChannel
    
    init(configuration: SystemConfiguration) {
        self.configuration = configuration
        self.logger = configuration.makeLogger(label: "AlertManager")
        self.notificationChannel = ConsoleNotificationChannel()
    }
    
    func start() async throws {
        logger.info("Starting alert manager")
    }
    
    func stop() async throws {
        logger.info("Stopping alert manager")
    }
    
    func addAlert(_ alert: AlertConfiguration) {
        alerts.append(alert)
        logger.debug("Added alert: \(alert.name)")
    }
    
    func checkAlerts(for metric: MetricData) {
        for alertConfig in alerts {
            if alertConfig.metricName == metric.name {
                let shouldTrigger = evaluateCondition(alertConfig.condition, value: metric.value)
                
                if shouldTrigger {
                    let alert = Alert(
                        id: EntityID(),
                        configuration: alertConfig,
                        triggeredAt: Timestamp(),
                        currentValue: metric.value,
                        tags: metric.tags
                    )
                    
                    triggerAlert(alert)
                }
            }
        }
    }
    
    func getActiveAlerts() -> [Alert] {
        return activeAlerts.filter { !$0.isResolved }
    }
    
    func resolveAlert(_ alertID: EntityID) {
        if let index = activeAlerts.firstIndex(where: { $0.id == alertID }) {
            activeAlerts[index].resolve()
        }
    }
    
    private func evaluateCondition(_ condition: AlertCondition, value: Double) -> Bool {
        switch condition {
        case .greaterThan(let threshold):
            return value > threshold
        case .lessThan(let threshold):
            return value < threshold
        case .between(let min, let max):
            return value >= min && value <= max
        case .outside(let min, let max):
            return value < min || value > max
        }
    }
    
    private func triggerAlert(_ alert: Alert) {
        activeAlerts.append(alert)
        
        let notification = Notification(
            title: "Alert: \(alert.configuration.name)",
            message: "Metric \(alert.configuration.metricName) triggered alert. Current value: \(alert.currentValue)",
            severity: alert.configuration.severity,
            timestamp: alert.triggeredAt
        )
        
        Task {
            await notificationChannel.send(notification)
        }
        
        logger.warning("Alert triggered: \(alert.configuration.name)")
    }
}

// MARK: - Dashboard

/// Real-time dashboard for system monitoring
actor Dashboard {
    private var currentData: DashboardData
    private let updateInterval: TimeInterval = 5.0
    private var isRunning: Bool = false
    
    init() {
        self.currentData = DashboardData()
    }
    
    func start() async throws {
        isRunning = true
        
        Task {
            await updateLoop()
        }
    }
    
    func stop() async throws {
        isRunning = false
    }
    
    func getCurrentData() -> DashboardData {
        return currentData
    }
    
    private func updateLoop() async {
        while isRunning {
            try? await Task.sleep(nanoseconds: UInt64(updateInterval * 1_000_000_000))
            
            await updateData()
        }
    }
    
    private func updateData() async {
        currentData = DashboardData(
            systemUptime: ProcessInfo.processInfo.systemUptime,
            memoryUsage: getMemoryUsage(),
            cpuUsage: getCPUUsage(),
            activeTasks: 0,
            completedTasks: 0,
            errorRate: 0.0,
            averageResponseTime: 0.0,
            lastUpdated: Timestamp()
        )
    }
    
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1_073_741_824 // Convert to GB
        }
        
        return 0.0
    }
    
    private func getCPUUsage() -> Double {
        var info = task_thread_times_info()
        var count = mach_msg_type_number_t(MemoryLayout<task_thread_times_info>.size / MemoryLayout<integer_t>.size)
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(TASK_THREAD_TIMES_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let totalTime = info.user_time.seconds + info.system_time.seconds
            return Double(totalTime) * 100.0
        }
        
        return 0.0
    }
}

// MARK: - Metrics Collector

/// Collects and aggregates system metrics
actor MetricsCollector {
    private var isRunning: Bool = false
    private let collectionInterval: TimeInterval = 10.0
    
    func start() async throws {
        isRunning = true
        
        Task {
            await collectionLoop()
        }
    }
    
    func stop() async throws {
        isRunning = false
    }
    
    private func collectionLoop() async {
        while isRunning {
            try? await Task.sleep(nanoseconds: UInt64(collectionInterval * 1_000_000_000))
            
            await collectMetrics()
        }
    }
    
    private func collectMetrics() async {
        collectTaskMetrics()
        collectPerformanceMetrics()
        collectResourceMetrics()
    }
    
    private func collectTaskMetrics() {
        // Implementation would collect task-related metrics
    }
    
    private func collectPerformanceMetrics() {
        // Implementation would collect performance metrics
    }
    
    private func collectResourceMetrics() {
        // Implementation would collect system resource metrics
    }
}

// MARK: - Data Types

/// Event data structure
public struct EventData: Hashable, Codable, Sendable {
    public let name: String
    public let timestamp: Timestamp
    public let properties: [String: String]
    
    public init(name: String, timestamp: Timestamp, properties: [String: String]) {
        self.name = name
        self.timestamp = timestamp
        self.properties = properties
    }
}

/// Alert configuration
public struct AlertConfiguration: Hashable, Codable, Sendable {
    public let name: String
    public let metricName: String
    public let condition: AlertCondition
    public let severity: AlertSeverity
    public let cooldownPeriod: TimeInterval
    
    public init(
        name: String,
        metricName: String,
        condition: AlertCondition,
        severity: AlertSeverity = .medium,
        cooldownPeriod: TimeInterval = 300
    ) {
        self.name = name
        self.metricName = metricName
        self.condition = condition
        self.severity = severity
        self.cooldownPeriod = cooldownPeriod
    }
}

/// Alert condition
public enum AlertCondition: Hashable, Codable, Sendable {
    case greaterThan(Double)
    case lessThan(Double)
    case between(Double, Double)
    case outside(Double, Double)
}

/// Alert severity
public enum AlertSeverity: String, Hashable, Codable, Sendable {
    case low
    case medium
    case high
    case critical
}

/// Alert structure
public struct Alert: Hashable, Codable, Sendable {
    public let id: EntityID
    public let configuration: AlertConfiguration
    public let triggeredAt: Timestamp
    public let currentValue: Double
    public let tags: [String: String]
    public var resolvedAt: Timestamp?
    
    public var isResolved: Bool {
        return resolvedAt != nil
    }
    
    public mutating func resolve() {
        resolvedAt = Timestamp()
    }
}

/// Notification structure
public struct Notification: Sendable {
    public let title: String
    public let message: String
    public let severity: AlertSeverity
    public let timestamp: Timestamp
}

/// Dashboard data
public struct DashboardData: Sendable {
    public let systemUptime: TimeInterval
    public let memoryUsage: Double
    public let cpuUsage: Double
    public let activeTasks: Int
    public let completedTasks: Int
    public let errorRate: Double
    public let averageResponseTime: TimeInterval
    public let lastUpdated: Timestamp
    
    public init() {
        self.systemUptime = 0
        self.memoryUsage = 0
        self.cpuUsage = 0
        self.activeTasks = 0
        self.completedTasks = 0
        self.errorRate = 0
        self.averageResponseTime = 0
        self.lastUpdated = Timestamp()
    }
    
    public init(
        systemUptime: TimeInterval,
        memoryUsage: Double,
        cpuUsage: Double,
        activeTasks: Int,
        completedTasks: Int,
        errorRate: Double,
        averageResponseTime: TimeInterval,
        lastUpdated: Timestamp
    ) {
        self.systemUptime = systemUptime
        self.memoryUsage = memoryUsage
        self.cpuUsage = cpuUsage
        self.activeTasks = activeTasks
        self.completedTasks = completedTasks
        self.errorRate = errorRate
        self.averageResponseTime = averageResponseTime
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Notification Channels

protocol NotificationChannel: Sendable {
    func send(_ notification: Notification) async
}

struct ConsoleNotificationChannel: NotificationChannel {
    func send(_ notification: Notification) {
        let timestamp = DateFormatter().string(from: Date())
        print("[\(timestamp)] [\(notification.severity.rawValue.uppercased())] \(notification.title)")
        print("  \(notification.message)")
        print()
    }
}

#if canImport(UserNotifications)
import UserNotifications

struct PushNotificationChannel: NotificationChannel {
    func send(_ notification: Notification) {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.message
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
#endif