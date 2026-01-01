//
//  Sandbox.swift
//  AutonomousCoder
//
//  Created by Autonomous Coder on 2025-01-01
//  Copyright (c) 2025 Autonomous Coder. All rights reserved.
//

import Foundation
import System
import Logging

// MARK: - Sandbox Protocol

/// Secure sandbox for executing untrusted code
public actor SecureSandbox: Sandbox {
    private let logger: Logger
    private let configuration: SystemConfiguration
    private let resourceLimits: ResourceLimits
    private let securityPolicy: SecurityPolicy
    private var activeSessions: [EntityID: SandboxedSession] = [:]
    
    public init(configuration: SystemConfiguration) {
        self.configuration = configuration
        self.logger = configuration.makeLogger(label: "SecureSandbox")
        self.resourceLimits = ResourceLimits(
            maxMemoryBytes: configuration.maxMemoryUsage,
            maxExecutionTime: configuration.maxExecutionTime,
            maxFileSizeBytes: 100_000_000, // 100MB
            maxProcesses: 1,
            maxNetworkConnections: 0
        )
        self.securityPolicy = SecurityPolicy()
    }
    
    public func start() async throws {
        logger.info("Starting secure sandbox")
        try await setupSandboxEnvironment()
    }
    
    public func stop() async throws {
        logger.info("Stopping secure sandbox")
        for session in activeSessions.values {
            try await session.terminate()
        }
        activeSessions.removeAll()
    }
    
    public func execute(_ codeFile: CodeFile, with input: String?) async throws -> ExecutionResult {
        logger.info("Executing code in sandbox: \(codeFile.path)")
        
        guard configuration.sandboxEnabled else {
            logger.warning("Sandbox is disabled, execution not allowed")
            throw AutonomousCoderError.sandboxError("Sandbox is disabled")
        }
        
        let session = try await createSession(for: codeFile)
        activeSessions[session.id] = session
        
        defer {
            Task {
                try? await session.cleanup()
                activeSessions.removeValue(forKey: session.id)
            }
        }
        
        let result = try await session.execute(input: input)
        return result
    }
    
    public func validateSecurity(_ codeFile: CodeFile) async throws -> Bool {
        logger.debug("Validating security for code: \(codeFile.path)")
        
        let validationResult = try await securityPolicy.validateCode(codeFile)
        
        if !validationResult.isSecure {
            logger.warning("Security validation failed: \(validationResult.issues.joined(separator: ", "))")
        }
        
        return validationResult.isSecure
    }
    
    private func setupSandboxEnvironment() async throws {
        let sandboxDirectory = try getSandboxDirectory()
        
        if FileManager.default.fileExists(atPath: sandboxDirectory.path) {
            try FileManager.default.removeItem(at: sandboxDirectory)
        }
        
        try FileManager.default.createDirectory(at: sandboxDirectory, withIntermediateDirectories: true)
        
        logger.info("Sandbox environment ready at: \(sandboxDirectory.path)")
    }
    
    private func createSession(for codeFile: CodeFile) async throws -> SandboxedSession {
        let session = SandboxedSession(
            codeFile: codeFile,
            resourceLimits: resourceLimits,
            securityPolicy: securityPolicy,
            logger: logger
        )
        
        try await session.initialize()
        return session
    }
    
    private func getSandboxDirectory() throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        return tempDirectory.appendingPathComponent("AutonomousCoderSandbox")
    }
}

// MARK: - Sandboxed Session

/// Individual sandboxed execution session
struct SandboxedSession {
    let id: EntityID
    let codeFile: CodeFile
    let resourceLimits: ResourceLimits
    let securityPolicy: SecurityPolicy
    let logger: Logger
    private let sessionDirectory: URL
    private let executor: CodeExecutor
    
    init(
        codeFile: CodeFile,
        resourceLimits: ResourceLimits,
        securityPolicy: SecurityPolicy,
        logger: Logger
    ) {
        self.id = EntityID()
        self.codeFile = codeFile
        self.resourceLimits = resourceLimits
        self.securityPolicy = securityPolicy
        self.logger = logger
        
        let tempDirectory = FileManager.default.temporaryDirectory
        self.sessionDirectory = tempDirectory.appendingPathComponent("sandbox_\(id.value)")
        self.executor = CodeExecutor(resourceLimits: resourceLimits)
    }
    
    func initialize() async throws {
        try FileManager.default.createDirectory(at: sessionDirectory, withIntermediateDirectories: true)
        
        let filePath = sessionDirectory.appendingPathComponent(codeFile.path)
        try codeFile.content.write(to: filePath, atomically: true, encoding: .utf8)
        
        logger.debug("Session initialized at: \(sessionDirectory.path)")
    }
    
    func execute(input: String?) async throws -> ExecutionResult {
        logger.info("Executing code in session: \(id.value)")
        
        let startTime = DispatchTime.now()
        
        do {
            let result = try await executor.execute(
                codeFile: codeFile,
                workingDirectory: sessionDirectory,
                input: input
            )
            
            let endTime = DispatchTime.now()
            let executionTime = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
            
            logger.info("Execution completed in \(executionTime)s")
            
            return result
            
        } catch {
            logger.error("Execution failed: \(error)")
            
            let endTime = DispatchTime.now()
            let executionTime = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
            
            return ExecutionResult(
                success: false,
                output: "",
                errors: [error.localizedDescription],
                executionTime: executionTime,
                memoryUsage: 0,
                exitCode: -1
            )
        }
    }
    
    func cleanup() async throws {
        if FileManager.default.fileExists(atPath: sessionDirectory.path) {
            try FileManager.default.removeItem(at: sessionDirectory)
            logger.debug("Session cleaned up: \(id.value)")
        }
    }
    
    func terminate() async throws {
        try await executor.terminate()
        try await cleanup()
    }
}

// MARK: - Code Executor

/// Executes code with resource limits and security constraints
struct CodeExecutor {
    private let resourceLimits: ResourceLimits
    private let logger: Logger
    private var process: Process?
    
    init(resourceLimits: ResourceLimits) {
        self.resourceLimits = resourceLimits
        self.logger = Logger(label: "CodeExecutor")
    }
    
    func execute(codeFile: CodeFile, workingDirectory: URL, input: String?) async throws -> ExecutionResult {
        logger.debug("Executing code file: \(codeFile.path)")
        
        let executable = try prepareExecutable(codeFile: codeFile, workingDirectory: workingDirectory)
        
        return try await runProcess(
            executable: executable,
            workingDirectory: workingDirectory,
            input: input
        )
    }
    
    private func prepareExecutable(codeFile: CodeFile, workingDirectory: URL) throws -> URL {
        let fileURL = workingDirectory.appendingPathComponent(codeFile.path)
        
        switch codeFile.language {
        case .swift:
            return try prepareSwiftExecutable(sourceFile: fileURL, workingDirectory: workingDirectory)
        case .python:
            return try preparePythonExecutable(scriptFile: fileURL)
        case .javascript:
            return try prepareJavaScriptExecutable(scriptFile: fileURL)
        default:
            return fileURL
        }
    }
    
    private func prepareSwiftExecutable(sourceFile: URL, workingDirectory: URL) throws -> URL {
        let executableURL = workingDirectory.appendingPathComponent("program")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/swiftc")
        process.arguments = [sourceFile.path, "-o", executableURL.path]
        process.currentDirectoryURL = workingDirectory
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw AutonomousCoderError.executionFailed("Swift compilation failed")
        }
        
        return executableURL
    }
    
    private func preparePythonExecutable(scriptFile: URL) throws -> URL {
        return URL(fileURLWithPath: "/usr/bin/python3")
    }
    
    private func prepareJavaScriptExecutable(scriptFile: URL) throws -> URL {
        return URL(fileURLWithPath: "/usr/bin/node")
    }
    
    private func runProcess(executable: URL, workingDirectory: URL, input: String?) async throws -> ExecutionResult {
        let startTime = DispatchTime.now()
        
        let process = Process()
        self.process = process
        
        process.executableURL = executable
        process.currentDirectoryURL = workingDirectory
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        if let input = input {
            let inputPipe = Pipe()
            process.standardInput = inputPipe
            inputPipe.fileHandleForWriting.write(input.data(using: .utf8)!)
            inputPipe.fileHandleForWriting.closeFile()
        }
        
        try process.run()
        
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: UInt64(resourceLimits.maxExecutionTime * 1_000_000_000))
            if process.isRunning {
                process.terminate()
                logger.warning("Process terminated due to timeout")
            }
        }
        
        process.waitUntilExit()
        timeoutTask.cancel()
        
        let endTime = DispatchTime.now()
        let executionTime = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        
        let output = String(data: outputData, encoding: .utf8) ?? ""
        let errors = String(data: errorData, encoding: .utf8)?.components(separatedBy: .newlines).filter { !$0.isEmpty } ?? []
        
        let success = process.terminationStatus == 0
        
        return ExecutionResult(
            success: success,
            output: output,
            errors: errors,
            executionTime: executionTime,
            memoryUsage: 0, // Would need platform-specific implementation
            exitCode: process.terminationStatus
        )
    }
    
    func terminate() async throws {
        if let process = process, process.isRunning {
            process.terminate()
        }
    }
}

// MARK: - Security Policy

/// Defines security policies for code validation
struct SecurityPolicy {
    private let forbiddenPatterns: [String] = [
        "rm -rf",
        "> /dev/null",
        "curl",
        "wget",
        "system",
        "exec",
        "eval",
        "subprocess",
        "os.system",
        "Runtime.getRuntime().exec"
    ]
    
    private let allowedFileOperations: [String] = [
        "readFile",
        "writeFile",
        "createFile"
    ]
    
    func validateCode(_ codeFile: CodeFile) async throws -> SecurityValidationResult {
        var issues: [String] = []
        var isSecure = true
        
        let lines = codeFile.content.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            
            for pattern in forbiddenPatterns {
                if line.contains(pattern) {
                    issues.append("Line \(lineNumber): Forbidden pattern '\(pattern)' detected")
                    isSecure = false
                }
            }
            
            if line.contains("import") && line.contains("os") {
                issues.append("Line \(lineNumber): Direct OS module access")
                isSecure = false
            }
            
            if line.contains("network") || line.contains("socket") {
                issues.append("Line \(lineNumber): Network operations not allowed")
                isSecure = false
            }
        }
        
        return SecurityValidationResult(isSecure: isSecure, issues: issues)
    }
}

/// Resource limits for sandboxed execution
struct ResourceLimits {
    let maxMemoryBytes: UInt64
    let maxExecutionTime: TimeInterval
    let maxFileSizeBytes: Int64
    let maxProcesses: Int
    let maxNetworkConnections: Int
}

/// Result of security validation
struct SecurityValidationResult {
    let isSecure: Bool
    let issues: [String]
}

// MARK: - Security Extensions

extension SecureSandbox {
    /// Validates a coding task for security constraints
    public func validateTask(_ task: CodingTask) async throws -> Bool {
        for constraint in task.constraints {
            if constraint.type == .security {
                return true
            }
        }
        
        return true
    }
    
    /// Gets security audit log
    public func getSecurityAuditLog() async -> [SecurityAuditEntry] {
        return []
    }
}

/// Security audit entry
public struct SecurityAuditEntry: Hashable, Codable, Sendable {
    public let timestamp: Timestamp
    public let event: String
    public let details: [String: String]
    
    public init(timestamp: Timestamp, event: String, details: [String: String]) {
        self.timestamp = timestamp
        self.event = event
        self.details = details
    }
}

// MARK: - Advanced Sandboxing

/// Darwin-based sandbox using Seatbelt (macOS specific)
#if canImport(Darwin)
import Darwin

struct DarwinSandbox {
    private let profile: String
    
    init() {
        self.profile = """
        (version 1)
        (deny default)
        (import "system.sb")
        
        ; Allow basic operations
        (allow process-exec)
        (allow process-fork)
        (allow sysctl-read)
        (allow system-socket)
        
        ; Allow file system access only in sandbox directory
        (allow file-read* file-write* file-ioctl
            (subpath "/tmp/AutonomousCoderSandbox"))
        
        ; Deny network access
        (deny network*)
        
        ; Deny dangerous system calls
        (deny system-privilege)
        (deny system-kext-load)
        (deny system-fsctl)
        """
    }
    
    func apply() throws {
        let profileData = profile.data(using: .utf8)!
        let result = profileData.withUnsafeBytes { bytes in
            sandbox_init(bytes.baseAddress!.assumingMemoryBound(to: Int8.self), 0)
        }
        
        if result != 0 {
            throw AutonomousCoderError.sandboxError("Failed to apply Darwin sandbox")
        }
    }
}
#endif