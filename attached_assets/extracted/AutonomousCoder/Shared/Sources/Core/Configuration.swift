//
//  Configuration.swift
//  AutonomousCoder
//
//  Created by Autonomous Coder on 2025-01-01
//  Copyright (c) 2025 Autonomous Coder. All rights reserved.
//

import Foundation
import Logging

// MARK: - Configuration Manager

/// Manages system configuration with hot-reloading capabilities
public actor ConfigurationManager {
    private var currentConfig: SystemConfiguration
    private let configFilePath: URL
    private let fileManager: FileManager
    private var fileWatcher: FileWatcher?
    private var updateHandlers: [(SystemConfiguration) -> Void] = []
    
    public init(configFilePath: URL? = nil) throws {
        self.fileManager = FileManager.default
        
        if let configPath = configFilePath {
            self.configFilePath = configPath
        } else {
            let applicationSupport = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            self.configFilePath = applicationSupport
                .appendingPathComponent("AutonomousCoder")
                .appendingPathComponent("config.json")
        }
        
        try fileManager.createDirectory(
            at: configFilePath.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        if fileManager.fileExists(atPath: configFilePath.path) {
            self.currentConfig = try ConfigurationManager.loadConfiguration(from: configFilePath)
        } else {
            self.currentConfig = SystemConfiguration()
            try saveConfiguration()
        }
        
        setupFileWatcher()
    }
    
    public func getConfiguration() -> SystemConfiguration {
        return currentConfig
    }
    
    public func updateConfiguration(_ updates: (inout SystemConfiguration) -> Void) async throws {
        updates(&currentConfig)
        try saveConfiguration()
        notifyUpdateHandlers()
    }
    
    public func registerUpdateHandler(_ handler: @escaping (SystemConfiguration) -> Void) {
        updateHandlers.append(handler)
    }
    
    private func saveConfiguration() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(currentConfig)
        try data.write(to: configFilePath)
    }
    
    private static func loadConfiguration(from url: URL) throws -> SystemConfiguration {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(SystemConfiguration.self, from: data)
    }
    
    private func setupFileWatcher() {
        self.fileWatcher = FileWatcher(path: configFilePath.path) { [weak self] in
            Task { @MainActor in
                do {
                    try await self?.reloadConfiguration()
                } catch {
                    Logger(label: "ConfigurationManager").error("Failed to reload configuration: \(error)")
                }
            }
        }
    }
    
    private func reloadConfiguration() async throws {
        let newConfig = try ConfigurationManager.loadConfiguration(from: configFilePath)
        currentConfig = newConfig
        notifyUpdateHandlers()
    }
    
    private func notifyUpdateHandlers() {
        for handler in updateHandlers {
            handler(currentConfig)
        }
    }
}

// MARK: - File Watcher

private class FileWatcher {
    private let path: String
    private let callback: () -> Void
    private var stream: FSEventStreamRef?
    
    init?(path: String, callback: @escaping () -> Void) {
        self.path = path
        self.callback = callback
        
        let pathsToWatch = [path] as CFArray
        let context = UnsafeMutablePointer<FSEventStreamContext>.allocate(capacity: 1)
        context.initialize(to: FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        ))
        
        let stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            { _, _, _, _, _, _ in
                let watcher = Unmanaged<FileWatcher>.fromOpaque($0!).takeUnretainedValue()
                watcher.callback()
            },
            context,
            pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            1.0,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents)
        )
        
        guard let validStream = stream else {
            context.deallocate()
            return nil
        }
        
        self.stream = validStream
        FSEventStreamScheduleWithRunLoop(validStream, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        FSEventStreamStart(validStream)
        
        context.deallocate()
    }
    
    deinit {
        if let stream = stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
    }
}

// MARK: - Configuration Extensions

extension SystemConfiguration {
    /// Creates a logger with the configured log level
    public func makeLogger(label: String) -> Logger {
        var logger = Logger(label: label)
        
        switch loggingLevel {
        case .trace:
            logger.logLevel = .trace
        case .debug:
            logger.logLevel = .debug
        case .info:
            logger.logLevel = .info
        case .notice:
            logger.logLevel = .notice
        case .warning:
            logger.logLevel = .warning
        case .error:
            logger.logLevel = .error
        case .critical:
            logger.logLevel = .critical
        }
        
        return logger
    }
}

// MARK: - Validation

extension SystemConfiguration {
    /// Validates the configuration
    public func validate() throws {
        if maxCodeGenerationTime <= 0 {
            throw AutonomousCoderError.configurationError("maxCodeGenerationTime must be positive")
        }
        
        if maxExecutionTime <= 0 {
            throw AutonomousCoderError.configurationError("maxExecutionTime must be positive")
        }
        
        if maxMemoryUsage == 0 {
            throw AutonomousCoderError.configurationError("maxMemoryUsage must be greater than 0")
        }
        
        try performanceTargets.validate()
    }
}

extension PerformanceTargets {
    /// Validates performance targets
    public func validate() throws {
        func validateRange(_ value: Double, min: Double, max: Double, name: String) throws {
            if value < min || value > max {
                throw AutonomousCoderError.configurationError("\(name) must be between \(min) and \(max)")
            }
        }
        
        try validateRange(minComplexityScore, min: 0, max: 1, name: "minComplexityScore")
        try validateRange(minReadabilityScore, min: 0, max: 1, name: "minReadabilityScore")
        try validateRange(minMaintainabilityScore, min: 0, max: 1, name: "minMaintainabilityScore")
        try validateRange(minTestCoverage, min: 0, max: 1, name: "minTestCoverage")
        
        if maxExecutionTime <= 0 {
            throw AutonomousCoderError.configurationError("maxExecutionTime must be positive")
        }
        
        if maxMemoryUsage == 0 {
            throw AutonomousCoderError.configurationError("maxMemoryUsage must be greater than 0")
        }
    }
}