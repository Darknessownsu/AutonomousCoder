//
//  DataRepository.swift
//  AutonomousCoder
//
//  Created by Autonomous Coder on 2025-01-01
//  Copyright (c) 2025 Autonomous Coder. All rights reserved.
//

import Foundation
import Logging
import SQLiteKit
import Fluent
import NIOCore

// MARK: - Database Configuration

/// Configuration for database connections
public struct DatabaseConfiguration: Hashable, Codable, Sendable {
    public let databasePath: String
    public let maxConnections: Int
    public let connectionTimeout: TimeInterval
    
    public init(
        databasePath: String? = nil,
        maxConnections: Int = 10,
        connectionTimeout: TimeInterval = 30
    ) {
        if let path = databasePath {
            self.databasePath = path
        } else {
            let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            let appSupport = paths[0].appendingPathComponent("AutonomousCoder")
            self.databasePath = appSupport.appendingPathComponent("autonomous_coder.db").path
        }
        
        self.maxConnections = maxConnections
        self.connectionTimeout = connectionTimeout
    }
}

// MARK: - Database Manager

/// Manages database connections and migrations
public actor DatabaseManager {
    private let configuration: DatabaseConfiguration
    private let logger: Logger
    private var databases: [String: Database] = [:]
    private let migrations: [Migration]
    
    public init(configuration: DatabaseConfiguration, migrations: [Migration] = []) {
        self.configuration = configuration
        self.migrations = defaultMigrations + migrations
        self.logger = Logger(label: "DatabaseManager")
    }
    
    public func initialize() async throws {
        logger.info("Initializing database at: \(configuration.databasePath)")
        
        let databaseDirectory = URL(fileURLWithPath: configuration.databasePath).deletingLastPathComponent()
        try FileManager.default.createDirectory(at: databaseDirectory, withIntermediateDirectories: true)
        
        let database = try createDatabase()
        try await runMigrations(on: database)
        
        databases["default"] = database
        logger.info("Database initialized successfully")
    }
    
    private func createDatabase() throws -> Database {
        let sqliteConfiguration = SQLiteConfiguration(storage: .file(path: configuration.databasePath))
        let sqliteConnectionSource = SQLiteConnectionSource(
            configuration: sqliteConfiguration,
            threadPool: NIOThreadPool(numberOfThreads: 1)
        )
        
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let pool = EventLoopGroupConnectionPool(
            source: sqliteConnectionSource,
            on: eventLoopGroup,
            maxConnectionsPerEventLoop: configuration.maxConnections
        )
        
        let database = Database(pool)
        return database
    }
    
    private func runMigrations(on database: Database) async throws {
        logger.info("Running database migrations")
        
        for migration in migrations {
            try await migration.prepare(on: database)
            logger.debug("Applied migration: \(migration.name)")
        }
    }
    
    public func database() throws -> Database {
        guard let database = databases["default"] else {
            throw AutonomousCoderError.invalidState("Database not initialized")
        }
        return database
    }
}

// MARK: - Generic Repository Implementation

/// Generic repository implementation using Fluent
public actor FluentRepository<T>: Repository where T: Hashable & Codable & Sendable {
    public typealias ModelType = T
    
    private let database: Database
    private let logger: Logger
    private let entityName: String
    
    public init(database: Database, entityName: String) {
        self.database = database
        self.logger = Logger(label: "Repository.\(entityName)")
        self.entityName = entityName
    }
    
    public func save(_ item: T) async throws {
        logger.debug("Saving \(entityName): \(item)")
        
        let data = try JSONEncoder().encode(item)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        try await database.execute(
            sql: "INSERT OR REPLACE INTO \(entityName) (id, data) VALUES (?, ?)",
            binds: [UUID().uuidString, data]
        )
    }
    
    public func find(byID id: EntityID) async throws -> T? {
        logger.debug("Finding \(entityName) by ID: \(id.value)")
        
        let rows = try await database.execute(
            sql: "SELECT data FROM \(entityName) WHERE id = ?",
            binds: [id.value]
        )
        
        guard let row = rows.first,
              let data = row.column("data")?.data else {
            return nil
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    public func findAll() async throws -> [T] {
        logger.debug("Finding all \(entityName)")
        
        let rows = try await database.execute(
            sql: "SELECT data FROM \(entityName)"
        )
        
        return try rows.compactMap { row in
            guard let data = row.column("data")?.data else {
                return nil
            }
            return try JSONDecoder().decode(T.self, from: data)
        }
    }
    
    public func delete(_ item: T) async throws {
        logger.debug("Deleting \(entityName): \(item)")
        
        let data = try JSONEncoder().encode(item)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        if let id = json["id"] as? String {
            try await database.execute(
                sql: "DELETE FROM \(entityName) WHERE id = ?",
                binds: [id]
            )
        }
    }
    
    public func count() async throws -> Int {
        logger.debug("Counting \(entityName)")
        
        let rows = try await database.execute(
            sql: "SELECT COUNT(*) as count FROM \(entityName)"
        )
        
        guard let row = rows.first,
              let count = row.column("count")?.int else {
            return 0
        }
        
        return count
    }
}

// MARK: - Specialized Repositories

/// Repository for code files
public actor CodeFileRepository {
    private let repository: any Repository<CodeFile>
    private let logger: Logger
    
    public init(repository: any Repository<CodeFile>) {
        self.repository = repository
        self.logger = Logger(label: "CodeFileRepository")
    }
    
    public func saveCodeFile(_ codeFile: CodeFile) async throws {
        try await repository.save(codeFile)
    }
    
    public func findCodeFile(byID id: EntityID) async throws -> CodeFile? {
        return try await repository.find(byID: id)
    }
    
    public func findCodeFiles(byLanguage language: ProgrammingLanguage) async throws -> [CodeFile] {
        let allFiles = try await repository.findAll()
        return allFiles.filter { $0.language == language }
    }
    
    public func findCodeFiles(byPath path: String) async throws -> [CodeFile] {
        let allFiles = try await repository.findAll()
        return allFiles.filter { $0.path.contains(path) }
    }
    
    public func deleteCodeFile(_ codeFile: CodeFile) async throws {
        try await repository.delete(codeFile)
    }
}

/// Repository for coding tasks
public actor CodingTaskRepository {
    private let repository: any Repository<CodingTask>
    private let logger: Logger
    
    public init(repository: any Repository<CodingTask>) {
        self.repository = repository
        self.logger = Logger(label: "CodingTaskRepository")
    }
    
    public func saveTask(_ task: CodingTask) async throws {
        try await repository.save(task)
    }
    
    public func findTask(byID id: EntityID) async throws -> CodingTask? {
        return try await repository.find(byID: id)
    }
    
    public func findTasks(byLanguage language: ProgrammingLanguage) async throws -> [CodingTask] {
        let allTasks = try await repository.findAll()
        return allTasks.filter { $0.targetLanguage == language }
    }
    
    public func findTasks(byDifficulty difficulty: DifficultyLevel) async throws -> [CodingTask] {
        let allTasks = try await repository.findAll()
        return allTasks.filter { $0.difficulty == difficulty }
    }
    
    public func findTasks(byTag tag: String) async throws -> [CodingTask] {
        let allTasks = try await repository.findAll()
        return allTasks.filter { $0.tags.contains(tag) }
    }
}

/// Repository for evaluation results
public actor EvaluationResultRepository {
    private let repository: any Repository<EvaluationResult>
    private let logger: Logger
    
    public init(repository: any Repository<EvaluationResult>) {
        self.repository = repository
        self.logger = Logger(label: "EvaluationResultRepository")
    }
    
    public func saveResult(_ result: EvaluationResult) async throws {
        try await repository.save(result)
    }
    
    public func findResult(byID id: EntityID) async throws -> EvaluationResult? {
        return try await repository.find(byID: id)
    }
    
    public func findResults(byTaskID taskID: EntityID) async throws -> [EvaluationResult] {
        let allResults = try await repository.findAll()
        return allResults.filter { $0.taskID == taskID }
    }
    
    public func findResults(since timestamp: Timestamp) async throws -> [EvaluationResult] {
        let allResults = try await repository.findAll()
        return allResults.filter { $0.timestamp > timestamp }
    }
    
    public func getAveragePerformance() async throws -> PerformanceMetrics {
        let allResults = try await repository.findAll()
        
        guard !allResults.isEmpty else {
            return PerformanceMetrics()
        }
        
        let totalMetrics = allResults.reduce(PerformanceMetrics()) { partialResult, result in
            PerformanceMetrics(
                executionTime: partialResult.executionTime + result.performanceMetrics.executionTime,
                memoryUsage: partialResult.memoryUsage + result.performanceMetrics.memoryUsage,
                cpuUsage: partialResult.cpuUsage + result.performanceMetrics.cpuUsage,
                complexityScore: partialResult.complexityScore + result.performanceMetrics.complexityScore,
                readabilityScore: partialResult.readabilityScore + result.performanceMetrics.readabilityScore,
                maintainabilityScore: partialResult.maintainabilityScore + result.performanceMetrics.maintainabilityScore,
                testCoverage: partialResult.testCoverage + result.performanceMetrics.testCoverage,
                benchmarkScore: partialResult.benchmarkScore + result.performanceMetrics.benchmarkScore
            )
        }
        
        let count = Double(allResults.count)
        
        return PerformanceMetrics(
            executionTime: totalMetrics.executionTime / count,
            memoryUsage: totalMetrics.memoryUsage / UInt64(count),
            cpuUsage: totalMetrics.cpuUsage / count,
            complexityScore: totalMetrics.complexityScore / count,
            readabilityScore: totalMetrics.readabilityScore / count,
            maintainabilityScore: totalMetrics.maintainabilityScore / count,
            testCoverage: totalMetrics.testCoverage / count,
            benchmarkScore: totalMetrics.benchmarkScore / count
        )
    }
}

// MARK: - Data Pipeline

/// Manages the data pipeline for continuous learning
public actor DataPipeline {
    private let logger: Logger
    private let configuration: DatabaseConfiguration
    private let eventStream: AsyncStream<DataEvent>
    private let eventContinuation: AsyncStream<DataEvent>.Continuation
    
    public init(configuration: DatabaseConfiguration) {
        self.configuration = configuration
        self.logger = Logger(label: "DataPipeline")
        
        let (stream, continuation) = AsyncStream<DataEvent>.makeStream()
        self.eventStream = stream
        self.eventContinuation = continuation
    }
    
    public func start() async throws {
        logger.info("Starting data pipeline")
        
        Task {
            await processEvents()
        }
    }
    
    public func stop() async throws {
        logger.info("Stopping data pipeline")
        eventContinuation.finish()
    }
    
    public func ingest(_ event: DataEvent) {
        logger.debug("Ingesting event: \(event.type)")
        eventContinuation.yield(event)
    }
    
    public func getEventStream() -> AsyncStream<DataEvent> {
        return eventStream
    }
    
    private func processEvents() async {
        logger.info("Starting event processing")
        
        for await event in eventStream {
            do {
                try await processEvent(event)
            } catch {
                logger.error("Failed to process event: \(error)")
            }
        }
    }
    
    private func processEvent(_ event: DataEvent) async throws {
        switch event.type {
        case .codeGenerated:
            logger.debug("Processing code generated event")
            try await handleCodeGenerated(event)
            
        case .evaluationCompleted:
            logger.debug("Processing evaluation completed event")
            try await handleEvaluationCompleted(event)
            
        case .improvementApplied:
            logger.debug("Processing improvement applied event")
            try await handleImprovementApplied(event)
            
        case .feedbackReceived:
            logger.debug("Processing feedback received event")
            try await handleFeedbackReceived(event)
        }
    }
    
    private func handleCodeGenerated(_ event: DataEvent) async throws {
        guard let codeFile = event.payload["code_file"] as? CodeFile else {
            return
        }
        
        logger.info("Code generated: \(codeFile.path)")
    }
    
    private func handleEvaluationCompleted(_ event: DataEvent) async throws {
        guard let result = event.payload["result"] as? EvaluationResult else {
            return
        }
        
        logger.info("Evaluation completed for task: \(result.taskID.value)")
    }
    
    private func handleImprovementApplied(_ event: DataEvent) async throws {
        guard let action = event.payload["action"] as? ImprovementAction else {
            return
        }
        
        logger.info("Improvement applied: \(action.type.rawValue)")
    }
    
    private func handleFeedbackReceived(_ event: DataEvent) async throws {
        guard let feedback = event.payload["feedback"] as? FeedbackItem else {
            return
        }
        
        logger.info("Feedback received: \(feedback.message)")
    }
}

// MARK: - Data Event

/// Represents an event in the data pipeline
public struct DataEvent: Sendable {
    public enum EventType: String, Sendable {
        case codeGenerated = "code_generated"
        case evaluationCompleted = "evaluation_completed"
        case improvementApplied = "improvement_applied"
        case feedbackReceived = "feedback_received"
    }
    
    public let id: EntityID
    public let type: EventType
    public let timestamp: Timestamp
    public let payload: [String: Any]
    
    public init(
        id: EntityID = EntityID(),
        type: EventType,
        payload: [String: Any] = [:]
    ) {
        self.id = id
        self.type = type
        self.timestamp = Timestamp()
        self.payload = payload
    }
}

// MARK: - Default Migrations

private let defaultMigrations: [Migration] = [
    CreateCodeFilesTable(),
    CreateCodingTasksTable(),
    CreateEvaluationResultsTable(),
    CreateImprovementActionsTable(),
    CreateLearningExperiencesTable()
]

// MARK: - Database Migrations

protocol Migration {
    var name: String { get }
    func prepare(on database: Database) async throws
}

struct CreateCodeFilesTable: Migration {
    let name = "create_code_files_table"
    
    func prepare(on database: Database) async throws {
        try await database.execute(sql: """
            CREATE TABLE IF NOT EXISTS code_files (
                id TEXT PRIMARY KEY,
                data BLOB NOT NULL,
                created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
                updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
            )
        """)
    }
}

struct CreateCodingTasksTable: Migration {
    let name = "create_coding_tasks_table"
    
    func prepare(on database: Database) async throws {
        try await database.execute(sql: """
            CREATE TABLE IF NOT EXISTS coding_tasks (
                id TEXT PRIMARY KEY,
                data BLOB NOT NULL,
                created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
                updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
            )
        """)
    }
}

struct CreateEvaluationResultsTable: Migration {
    let name = "create_evaluation_results_table"
    
    func prepare(on database: Database) async throws {
        try await database.execute(sql: """
            CREATE TABLE IF NOT EXISTS evaluation_results (
                id TEXT PRIMARY KEY,
                data BLOB NOT NULL,
                created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
                updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
            )
        """)
    }
}

struct CreateImprovementActionsTable: Migration {
    let name = "create_improvement_actions_table"
    
    func prepare(on database: Database) async throws {
        try await database.execute(sql: """
            CREATE TABLE IF NOT EXISTS improvement_actions (
                id TEXT PRIMARY KEY,
                data BLOB NOT NULL,
                created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
                updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
            )
        """)
    }
}

struct CreateLearningExperiencesTable: Migration {
    let name = "create_learning_experiences_table"
    
    func prepare(on database: Database) async throws {
        try await database.execute(sql: """
            CREATE TABLE IF NOT EXISTS learning_experiences (
                id TEXT PRIMARY KEY,
                data BLOB NOT NULL,
                created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
                updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
            )
        """)
    }
}

// MARK: - Database Extensions

extension Database {
    func execute(sql: String, binds: [Any] = []) async throws -> [SQLiteRow] {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let rows = try await self.raw(sql).binds(binds).all()
                    continuation.resume(returning: rows)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}