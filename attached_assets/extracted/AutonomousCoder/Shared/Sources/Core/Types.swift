//
//  Types.swift
//  AutonomousCoder
//
//  Created by Autonomous Coder on 2025-01-01
//  Copyright (c) 2025 Autonomous Coder. All rights reserved.
//

import Foundation
import Logging

// MARK: - Core Types

/// Represents a unique identifier for any entity in the system
public struct EntityID: Hashable, Codable, Sendable {
    public let value: String
    
    public init(_ value: String) {
        self.value = value
    }
    
    public init() {
        self.value = UUID().uuidString
    }
}

/// Represents a timestamp with nanosecond precision
public struct Timestamp: Hashable, Codable, Sendable, Comparable {
    public let nanoseconds: UInt64
    
    public init() {
        self.nanoseconds = DispatchTime.now().uptimeNanoseconds
    }
    
    public init(nanoseconds: UInt64) {
        self.nanoseconds = nanoseconds
    }
    
    public static func < (lhs: Timestamp, rhs: Timestamp) -> Bool {
        lhs.nanoseconds < rhs.nanoseconds
    }
    
    public static func == (lhs: Timestamp, rhs: Timestamp) -> Bool {
        lhs.nanoseconds == rhs.nanoseconds
    }
}

/// Represents a code file with its content and metadata
public struct CodeFile: Hashable, Codable, Sendable {
    public let id: EntityID
    public let path: String
    public let content: String
    public let language: ProgrammingLanguage
    public let createdAt: Timestamp
    public let modifiedAt: Timestamp
    public let metadata: [String: String]
    
    public init(
        id: EntityID = EntityID(),
        path: String,
        content: String,
        language: ProgrammingLanguage,
        createdAt: Timestamp = Timestamp(),
        modifiedAt: Timestamp = Timestamp(),
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.path = path
        self.content = content
        self.language = language
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.metadata = metadata
    }
}

/// Represents a programming language
public enum ProgrammingLanguage: String, Hashable, Codable, Sendable, CaseIterable {
    case swift
    case objectiveC = "objective-c"
    case python
    case javascript
    case typescript
    case java
    case cpp = "c++"
    case c
    case rust
    case go
    case kotlin
    case ruby
    case php
    case html
    case css
    case sql
    case shell
    case other(String)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        switch rawValue.lowercased() {
        case "swift": self = .swift
        case "objective-c", "objc": self = .objectiveC
        case "python", "py": self = .python
        case "javascript", "js": self = .javascript
        case "typescript", "ts": self = .typescript
        case "java": self = .java
        case "c++", "cpp", "cxx": self = .cpp
        case "c": self = .c
        case "rust", "rs": self = .rust
        case "go", "golang": self = .go
        case "kotlin", "kt": self = .kotlin
        case "ruby", "rb": self = .ruby
        case "php": self = .php
        case "html": self = .html
        case "css": self = .css
        case "sql": self = .sql
        case "shell", "bash", "sh": self = .shell
        default: self = .other(rawValue)
        }
    }
    
    public var fileExtensions: [String] {
        switch self {
        case .swift: return [".swift"]
        case .objectiveC: return [".m", ".h"]
        case .python: return [".py"]
        case .javascript: return [".js"]
        case .typescript: return [".ts", ".tsx"]
        case .java: return [".java"]
        case .cpp: return [".cpp", ".hpp", ".cc", ".cxx"]
        case .c: return [".c", ".h"]
        case .rust: return [".rs"]
        case .go: return [".go"]
        case .kotlin: return [".kt"]
        case .ruby: return [".rb"]
        case .php: return [".php"]
        case .html: return [".html", ".htm"]
        case .css: return [".css"]
        case .sql: return [".sql"]
        case .shell: return [".sh", ".bash"]
        case .other: return []
        }
    }
    
    public var description: String {
        switch self {
        case .swift: return "Swift"
        case .objectiveC: return "Objective-C"
        case .python: return "Python"
        case .javascript: return "JavaScript"
        case .typescript: return "TypeScript"
        case .java: return "Java"
        case .cpp: return "C++"
        case .c: return "C"
        case .rust: return "Rust"
        case .go: return "Go"
        case .kotlin: return "Kotlin"
        case .ruby: return "Ruby"
        case .php: return "PHP"
        case .html: return "HTML"
        case .css: return "CSS"
        case .sql: return "SQL"
        case .shell: return "Shell"
        case .other(let name): return name
        }
    }
}

/// Represents the result of code execution
public struct ExecutionResult: Hashable, Codable, Sendable {
    public let success: Bool
    public let output: String
    public let errors: [String]
    public let executionTime: TimeInterval
    public let memoryUsage: UInt64
    public let exitCode: Int32
    
    public init(
        success: Bool,
        output: String,
        errors: [String] = [],
        executionTime: TimeInterval = 0,
        memoryUsage: UInt64 = 0,
        exitCode: Int32 = 0
    ) {
        self.success = success
        self.output = output
        self.errors = errors
        self.executionTime = executionTime
        self.memoryUsage = memoryUsage
        self.exitCode = exitCode
    }
}

/// Represents a coding task or requirement
public struct CodingTask: Hashable, Codable, Sendable {
    public let id: EntityID
    public let title: String
    public let description: String
    public let requirements: [Requirement]
    public let constraints: [Constraint]
    public let targetLanguage: ProgrammingLanguage
    public let difficulty: DifficultyLevel
    public let tags: [String]
    public let createdAt: Timestamp
    
    public init(
        id: EntityID = EntityID(),
        title: String,
        description: String,
        requirements: [Requirement] = [],
        constraints: [Constraint] = [],
        targetLanguage: ProgrammingLanguage,
        difficulty: DifficultyLevel = .medium,
        tags: [String] = [],
        createdAt: Timestamp = Timestamp()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.requirements = requirements
        self.constraints = constraints
        self.targetLanguage = targetLanguage
        self.difficulty = difficulty
        self.tags = tags
        self.createdAt = createdAt
    }
}

/// Represents a requirement for a coding task
public struct Requirement: Hashable, Codable, Sendable {
    public let id: EntityID
    public let description: String
    public let priority: Priority
    public let isOptional: Bool
    
    public init(
        id: EntityID = EntityID(),
        description: String,
        priority: Priority = .medium,
        isOptional: Bool = false
    ) {
        self.id = id
        self.description = description
        self.priority = priority
        self.isOptional = isOptional
    }
}

/// Represents a constraint for a coding task
public struct Constraint: Hashable, Codable, Sendable {
    public enum ConstraintType: String, Hashable, Codable, Sendable {
        case timeComplexity = "time_complexity"
        case spaceComplexity = "space_complexity"
        case memoryLimit = "memory_limit"
        case executionTime = "execution_time"
        case codeStyle = "code_style"
        case architectural = "architectural"
        case security = "security"
        case performance = "performance"
    }
    
    public let type: ConstraintType
    public let description: String
    public let limit: String?
    
    public init(type: ConstraintType, description: String, limit: String? = nil) {
        self.type = type
        self.description = description
        self.limit = limit
    }
}

/// Represents task difficulty level
public enum DifficultyLevel: String, Hashable, Codable, Sendable, CaseIterable {
    case easy
    case medium
    case hard
    case expert
}

/// Represents priority levels
public enum Priority: String, Hashable, Codable, Sendable, CaseIterable {
    case low
    case medium
    case high
    case critical
}

// MARK: - Performance Metrics

/// Represents performance metrics for code evaluation
public struct PerformanceMetrics: Hashable, Codable, Sendable {
    public let executionTime: TimeInterval
    public let memoryUsage: UInt64
    public let cpuUsage: Double
    public let complexityScore: Double
    public let readabilityScore: Double
    public let maintainabilityScore: Double
    public let testCoverage: Double
    public let benchmarkScore: Double
    
    public init(
        executionTime: TimeInterval = 0,
        memoryUsage: UInt64 = 0,
        cpuUsage: Double = 0,
        complexityScore: Double = 0,
        readabilityScore: Double = 0,
        maintainabilityScore: Double = 0,
        testCoverage: Double = 0,
        benchmarkScore: Double = 0
    ) {
        self.executionTime = executionTime
        self.memoryUsage = memoryUsage
        self.cpuUsage = cpuUsage
        self.complexityScore = complexityScore
        self.readabilityScore = readabilityScore
        self.maintainabilityScore = maintainabilityScore
        self.testCoverage = testCoverage
        self.benchmarkScore = benchmarkScore
    }
    
    public var overallScore: Double {
        let weights = [
            complexityScore: 0.2,
            readabilityScore: 0.2,
            maintainabilityScore: 0.2,
            testCoverage: 0.2,
            benchmarkScore: 0.2
        ]
        
        return weights.reduce(0) { $0 + $1.key * $1.value }
    }
}

/// Represents an evaluation result
public struct EvaluationResult: Hashable, Codable, Sendable {
    public let taskID: EntityID
    public let codeFile: CodeFile
    public let performanceMetrics: PerformanceMetrics
    public let passedTests: Bool
    public let feedback: [FeedbackItem]
    public let suggestions: [Suggestion]
    public let timestamp: Timestamp
    
    public init(
        taskID: EntityID,
        codeFile: CodeFile,
        performanceMetrics: PerformanceMetrics,
        passedTests: Bool,
        feedback: [FeedbackItem] = [],
        suggestions: [Suggestion] = [],
        timestamp: Timestamp = Timestamp()
    ) {
        self.taskID = taskID
        self.codeFile = codeFile
        self.performanceMetrics = performanceMetrics
        self.passedTests = passedTests
        self.feedback = feedback
        self.suggestions = suggestions
        self.timestamp = timestamp
    }
}

/// Represents feedback on code quality
public struct FeedbackItem: Hashable, Codable, Sendable {
    public enum FeedbackType: String, Hashable, Codable, Sendable {
        case error
        case warning
        case suggestion
        case praise
    }
    
    public let type: FeedbackType
    public let message: String
    public let lineNumber: Int?
    public let severity: Severity
    
    public init(type: FeedbackType, message: String, lineNumber: Int? = nil, severity: Severity = .medium) {
        self.type = type
        self.message = message
        self.lineNumber = lineNumber
        self.severity = severity
    }
}

/// Represents a suggestion for improvement
public struct Suggestion: Hashable, Codable, Sendable {
    public enum SuggestionType: String, Hashable, Codable, Sendable {
        case optimization
        case refactoring
        case bugFix = "bug_fix"
        case styleImprovement = "style_improvement"
        case securityEnhancement = "security_enhancement"
        case performanceImprovement = "performance_improvement"
    }
    
    public let type: SuggestionType
    public let description: String
    public let codeExample: String?
    public let priority: Priority
    
    public init(type: SuggestionType, description: String, codeExample: String? = nil, priority: Priority = .medium) {
        self.type = type
        self.description = description
        self.codeExample = codeExample
        self.priority = priority
    }
}

/// Represents severity levels
public enum Severity: String, Hashable, Codable, Sendable, CaseIterable {
    case low
    case medium
    case high
    case critical
}

// MARK: - Self-Improvement Types

/// Represents a self-improvement action
public struct ImprovementAction: Hashable, Codable, Sendable {
    public enum ActionType: String, Hashable, Codable, Sendable {
        case codeGenerationStrategy = "code_generation_strategy"
        case algorithmOptimization = "algorithm_optimization"
        case architectureRefactoring = "architecture_refactoring"
        case trainingDataEnhancement = "training_data_enhancement"
        case modelParameterTuning = "model_parameter_tuning"
        case feedbackIntegration = "feedback_integration"
    }
    
    public let id: EntityID
    public let type: ActionType
    public let description: String
    public let parameters: [String: String]
    public let expectedOutcome: String
    public let priority: Priority
    public let status: ActionStatus
    public let createdAt: Timestamp
    public let appliedAt: Timestamp?
    
    public init(
        id: EntityID = EntityID(),
        type: ActionType,
        description: String,
        parameters: [String: String] = [:],
        expectedOutcome: String,
        priority: Priority = .medium,
        status: ActionStatus = .pending,
        createdAt: Timestamp = Timestamp(),
        appliedAt: Timestamp? = nil
    ) {
        self.id = id
        self.type = type
        self.description = description
        self.parameters = parameters
        self.expectedOutcome = expectedOutcome
        self.priority = priority
        self.status = status
        self.createdAt = createdAt
        self.appliedAt = appliedAt
    }
}

/// Represents the status of an improvement action
public enum ActionStatus: String, Hashable, Codable, Sendable, CaseIterable {
    case pending
    case inProgress = "in_progress"
    case completed
    case failed
    case cancelled
}

/// Represents a learning experience for the AI
public struct LearningExperience: Hashable, Codable, Sendable {
    public let id: EntityID
    public let taskID: EntityID
    public let actionTaken: ImprovementAction
    public let beforeMetrics: PerformanceMetrics
    public let afterMetrics: PerformanceMetrics
    public let success: Bool
    public let lessonsLearned: [String]
    public let timestamp: Timestamp
    
    public var improvementRatio: Double {
        guard beforeMetrics.overallScore > 0 else { return 0 }
        return (afterMetrics.overallScore - beforeMetrics.overallScore) / beforeMetrics.overallScore
    }
    
    public init(
        id: EntityID = EntityID(),
        taskID: EntityID,
        actionTaken: ImprovementAction,
        beforeMetrics: PerformanceMetrics,
        afterMetrics: PerformanceMetrics,
        success: Bool,
        lessonsLearned: [String] = [],
        timestamp: Timestamp = Timestamp()
    ) {
        self.id = id
        self.taskID = taskID
        self.actionTaken = actionTaken
        self.beforeMetrics = beforeMetrics
        self.afterMetrics = afterMetrics
        self.success = success
        self.lessonsLearned = lessonsLearned
        self.timestamp = timestamp
    }
}

// MARK: - System Configuration

/// Represents system configuration
public struct SystemConfiguration: Hashable, Codable, Sendable {
    public let maxCodeGenerationTime: TimeInterval
    public let maxExecutionTime: TimeInterval
    public let maxMemoryUsage: UInt64
    public let sandboxEnabled: Bool
    public let selfImprovementEnabled: Bool
    public let humanInTheLoop: Bool
    public let loggingLevel: LogLevel
    public let performanceTargets: PerformanceTargets
    
    public init(
        maxCodeGenerationTime: TimeInterval = 300,
        maxExecutionTime: TimeInterval = 60,
        maxMemoryUsage: UInt64 = 1_073_741_824, // 1GB
        sandboxEnabled: Bool = true,
        selfImprovementEnabled: Bool = true,
        humanInTheLoop: Bool = true,
        loggingLevel: LogLevel = .info,
        performanceTargets: PerformanceTargets = PerformanceTargets()
    ) {
        self.maxCodeGenerationTime = maxCodeGenerationTime
        self.maxExecutionTime = maxExecutionTime
        self.maxMemoryUsage = maxMemoryUsage
        self.sandboxEnabled = sandboxEnabled
        self.selfImprovementEnabled = selfImprovementEnabled
        self.humanInTheLoop = humanInTheLoop
        self.loggingLevel = loggingLevel
        self.performanceTargets = performanceTargets
    }
}

/// Represents performance targets for the AI
public struct PerformanceTargets: Hashable, Codable, Sendable {
    public let minComplexityScore: Double
    public let minReadabilityScore: Double
    public let minMaintainabilityScore: Double
    public let minTestCoverage: Double
    public let maxExecutionTime: TimeInterval
    public let maxMemoryUsage: UInt64
    
    public init(
        minComplexityScore: Double = 0.7,
        minReadabilityScore: Double = 0.8,
        minMaintainabilityScore: Double = 0.75,
        minTestCoverage: Double = 0.9,
        maxExecutionTime: TimeInterval = 30,
        maxMemoryUsage: UInt64 = 536_870_912 // 512MB
    ) {
        self.minComplexityScore = minComplexityScore
        self.minReadabilityScore = minReadabilityScore
        self.minMaintainabilityScore = minMaintainabilityScore
        self.minTestCoverage = minTestCoverage
        self.maxExecutionTime = maxExecutionTime
        self.maxMemoryUsage = maxMemoryUsage
    }
}

/// Represents logging levels
public enum LogLevel: String, Hashable, Codable, Sendable, CaseIterable {
    case trace
    case debug
    case info
    case notice
    case warning
    case error
    case critical
}

// MARK: - Error Types

/// Base error type for the system
public enum AutonomousCoderError: Error, Sendable {
    case invalidState(String)
    case resourceNotFound(String)
    case permissionDenied(String)
    case timeout(String)
    case validationFailed(String)
    case executionFailed(String)
    case improvementFailed(String)
    case sandboxError(String)
    case networkError(String)
    case configurationError(String)
}

// MARK: - Protocols

/// Represents a service that can be started and stopped
public protocol Service: Sendable {
    func start() async throws
    func stop() async throws
}

/// Represents an agent that can perform tasks
public protocol Agent: Service {
    var id: EntityID { get }
    var name: String { get }
    var capabilities: [Capability] { get }
    
    func canHandle(_ task: CodingTask) -> Bool
    func execute(_ task: CodingTask) async throws -> CodeFile
}

/// Represents a capability of an agent
public struct Capability: Hashable, Codable, Sendable {
    public let name: String
    public let description: String
    public let supportedLanguages: [ProgrammingLanguage]
    
    public init(name: String, description: String, supportedLanguages: [ProgrammingLanguage]) {
        self.name = name
        self.description = description
        self.supportedLanguages = supportedLanguages
    }
}

/// Represents a repository for storing and retrieving data
public protocol Repository: Sendable {
    associatedtype T: Hashable & Codable & Sendable
    
    func save(_ item: T) async throws
    func find(byID id: EntityID) async throws -> T?
    func findAll() async throws -> [T]
    func delete(_ item: T) async throws
    func count() async throws -> Int
}

/// Represents an evaluator for code quality
public protocol CodeEvaluator: Sendable {
    func evaluate(_ codeFile: CodeFile, for task: CodingTask) async throws -> EvaluationResult
}

/// Represents a code generator
public protocol CodeGenerator: Sendable {
    func generateCode(for task: CodingTask) async throws -> CodeFile
}

/// Represents a code debugger
public protocol CodeDebugger: Sendable {
    func debug(_ codeFile: CodeFile, errorDescription: String) async throws -> CodeFile
}

/// Represents a self-improvement mechanism
public protocol SelfImproving: Sendable {
    func analyzePerformance(_ evaluation: EvaluationResult) async throws -> [ImprovementAction]
    func apply(_ action: ImprovementAction) async throws
    func getLearningHistory() async throws -> [LearningExperience]
}

/// Represents a sandbox for secure code execution
public protocol Sandbox: Sendable {
    func execute(_ codeFile: CodeFile, with input: String?) async throws -> ExecutionResult
    func validateSecurity(_ codeFile: CodeFile) async throws -> Bool
}

/// Represents a monitoring system
public protocol MonitoringSystem: Service {
    func recordMetric(_ name: String, value: Double, tags: [String: String]) async
    func recordEvent(_ name: String, properties: [String: String]) async
    func getMetrics(for timeRange: TimeRange) async throws -> [MetricData]
}

/// Represents a time range for querying metrics
public struct TimeRange: Hashable, Sendable {
    public let start: Date
    public let end: Date
    
    public init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }
    
    public static func last(_ hours: Int) -> TimeRange {
        let end = Date()
        let start = end.addingTimeInterval(-Double(hours) * 3600)
        return TimeRange(start: start, end: end)
    }
}

/// Represents metric data
public struct MetricData: Hashable, Codable, Sendable {
    public let name: String
    public let value: Double
    public let timestamp: Timestamp
    public let tags: [String: String]
    
    public init(name: String, value: Double, timestamp: Timestamp, tags: [String: String]) {
        self.name = name
        self.value = value
        self.timestamp = timestamp
        self.tags = tags
    }
}