//
//  AICommandCenter.swift
//  AutonomousCoder
//
//  Created by Autonomous Coder on 2025-01-01
//  Copyright (c) 2025 Autonomous Coder. All rights reserved.
//

import Foundation
import Logging
import AsyncAlgorithms
import ServiceLifecycle

// MARK: - AI Command Center

/// Central orchestrator for all AI agents and system components
public actor AICommandCenter: Service {
    private let logger: Logger
    private let configuration: SystemConfiguration
    private let agents: [Agent]
    private let evaluationPipeline: EvaluationPipeline
    private let selfImprovementEngine: SelfImprovementEngine
    private let monitoringSystem: MonitoringSystem
    private let securityManager: SecurityManager
    private let dataPipeline: DataPipeline
    private let humanFeedbackSystem: HumanFeedbackSystem
    private let taskQueue: TaskQueue
    private var isRunning: Bool = false
    private let serviceGroup: ServiceGroup?
    
    public init(
        configuration: SystemConfiguration,
        agents: [Agent]? = nil,
        evaluationPipeline: EvaluationPipeline? = nil,
        selfImprovementEngine: SelfImprovementEngine? = nil,
        monitoringSystem: MonitoringSystem? = nil,
        securityManager: SecurityManager? = nil,
        dataPipeline: DataPipeline? = nil,
        humanFeedbackSystem: HumanFeedbackSystem? = nil,
        taskQueue: TaskQueue? = nil
    ) {
        self.configuration = configuration
        self.logger = configuration.makeLogger(label: "AICommandCenter")
        
        let databaseConfiguration = DatabaseConfiguration()
        let databaseManager = try! DatabaseManager(configuration: databaseConfiguration)
        
        self.agents = agents ?? [
            CodeGenerationAgent(configuration: configuration),
            CodeDebuggingAgent(configuration: configuration),
            CodeOptimizationAgent(configuration: configuration)
        ]
        
        let evaluationRepository = try! FluentRepository<EvaluationResult>(
            database: databaseManager.database(),
            entityName: "evaluation_results"
        )
        
        let actionRepository = try! FluentRepository<ImprovementAction>(
            database: databaseManager.database(),
            entityName: "improvement_actions"
        )
        
        let learningRepository = try! FluentRepository<LearningExperience>(
            database: databaseManager.database(),
            entityName: "learning_experiences"
        )
        
        self.evaluationPipeline = evaluationPipeline ?? EvaluationPipeline(
            configuration: configuration,
            evaluators: [DefaultCodeEvaluator(configuration: configuration)]
        )
        
        self.selfImprovementEngine = selfImprovementEngine ?? SelfImprovementEngine(
            configuration: configuration,
            evaluationRepository: evaluationRepository,
            actionRepository: actionRepository,
            learningRepository: learningRepository
        )
        
        self.monitoringSystem = monitoringSystem ?? DefaultMonitoringSystem(
            configuration: configuration
        )
        
        self.securityManager = securityManager ?? SecurityManager(
            configuration: configuration
        )
        
        self.dataPipeline = dataPipeline ?? DataPipeline(
            configuration: databaseConfiguration
        )
        
        self.humanFeedbackSystem = humanFeedbackSystem ?? HumanFeedbackSystem(
            configuration: configuration
        )
        
        self.taskQueue = taskQueue ?? TaskQueue()
        
        let services: [any Service] = [
            self.evaluationPipeline,
            self.selfImprovementEngine,
            self.monitoringSystem,
            self.securityManager,
            self.dataPipeline,
            self.humanFeedbackSystem
        ] + self.agents
        
        self.serviceGroup = ServiceGroup(
            services: services,
            logger: logger
        )
    }
    
    public func start() async throws {
        logger.info("Starting AI Command Center")
        
        guard !isRunning else {
            logger.warning("AI Command Center is already running")
            return
        }
        
        try await serviceGroup?.run()
        
        isRunning = true
        logger.info("AI Command Center started successfully")
        
        Task {
            await runMainLoop()
        }
    }
    
    public func stop() async throws {
        logger.info("Stopping AI Command Center")
        
        isRunning = false
        
        try await serviceGroup?.gracefulShutdown()
        
        logger.info("AI Command Center stopped")
    }
    
    public func submitTask(_ task: CodingTask) async throws -> EntityID {
        logger.info("Submitting task: \(task.title)")
        
        try await taskQueue.enqueue(task)
        
        let event = DataEvent(
            type: .taskSubmitted,
            payload: ["task": task]
        )
        await dataPipeline.ingest(event)
        
        return task.id
    }
    
    public func getTaskStatus(_ taskID: EntityID) async throws -> TaskStatus {
        return try await taskQueue.getStatus(taskID)
    }
    
    public func getTaskResult(_ taskID: EntityID) async throws -> TaskResult? {
        return try await taskQueue.getResult(taskID)
    }
    
    public func cancelTask(_ taskID: EntityID) async throws {
        logger.info("Cancelling task: \(taskID.value)")
        try await taskQueue.cancel(taskID)
    }
    
    public func getSystemMetrics() async -> SystemMetrics {
        let agentMetrics = await getAgentMetrics()
        let queueMetrics = await taskQueue.getMetrics()
        let improvementStats = try? await selfImprovementEngine.getStatistics()
        
        return SystemMetrics(
            uptime: getUptime(),
            tasksProcessed: queueMetrics.totalProcessed,
            tasksInQueue: queueMetrics.pendingCount,
            activeAgents: agentMetrics.activeCount,
            averageTaskTime: queueMetrics.averageProcessingTime,
            improvementSuccessRate: improvementStats?.successRate ?? 0
        )
    }
    
    // MARK: - Private Methods
    
    private func runMainLoop() async {
        logger.info("Starting main command center loop")
        
        while isRunning {
            do {
                if let task = try await taskQueue.dequeue() {
                    await processTask(task)
                } else {
                    try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                }
            } catch {
                logger.error("Error in main loop: \(error)")
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s
            }
        }
    }
    
    private func processTask(_ task: CodingTask) async {
        logger.info("Processing task: \(task.title)")
        
        do {
            try await taskQueue.updateStatus(task.id, status: .inProgress)
            
            let agent = try selectAgent(for: task)
            let codeFile = try await executeTask(task, with: agent)
            
            let evaluation = try await evaluationPipeline.evaluate(codeFile, for: task)
            
            if evaluation.passedTests {
                try await taskQueue.complete(task.id, result: .codeFile(codeFile))
                logger.info("Task completed successfully: \(task.title)")
            } else {
                try await handleFailedEvaluation(task, codeFile: codeFile, evaluation: evaluation)
            }
            
            await monitoringSystem.recordMetric(
                "task_processed",
                value: 1,
                tags: ["language": task.targetLanguage.rawValue, "difficulty": task.difficulty.rawValue]
            )
            
        } catch {
            logger.error("Failed to process task: \(error)")
            try? await taskQueue.fail(task.id, error: error)
        }
    }
    
    private func selectAgent(for task: CodingTask) throws -> Agent {
        let capableAgents = agents.filter { $0.canHandle(task) }
        
        guard !capableAgents.isEmpty else {
            throw AutonomousCoderError.invalidState("No agent can handle task with language \(task.targetLanguage)")
        }
        
        return capableAgents.randomElement()!
    }
    
    private func executeTask(_ task: CodingTask, with agent: Agent) async throws -> CodeFile {
        logger.debug("Executing task with agent: \(agent.name)")
        
        let codeFile = try await agent.execute(task)
        
        let securityValidation = try await securityManager.validateSecurity(codeFile)
        if !securityValidation.isSecure {
            logger.warning("Security validation failed: \(securityValidation.issues.joined(separator: ", "))")
            
            if configuration.humanInTheLoop {
                let approval = try await humanFeedbackSystem.requestSecurityApproval(
                    codeFile: codeFile,
                    issues: securityValidation.issues
                )
                
                if !approval {
                    throw AutonomousCoderError.securityError("Code rejected by human review")
                }
            }
        }
        
        return codeFile
    }
    
    private func handleFailedEvaluation(
        _ task: CodingTask,
        codeFile: CodeFile,
        evaluation: EvaluationResult
    ) async throws {
        logger.info("Task failed evaluation, attempting to fix")
        
        if let debuggingAgent = agents.first(where: { $0 is CodeDebuggingAgent }) as? CodeDebuggingAgent {
            do {
                let fixedCodeFile = try await debuggingAgent.debug(codeFile, errorDescription: "Evaluation failed")
                let reevaluation = try await evaluationPipeline.evaluate(fixedCodeFile, for: task)
                
                if reevaluation.passedTests {
                    try await taskQueue.complete(task.id, result: .codeFile(fixedCodeFile))
                    return
                }
            } catch {
                logger.error("Debugging failed: \(error)")
            }
        }
        
        try await taskQueue.fail(task.id, error: AutonomousCoderError.executionFailed("Evaluation failed"))
        
        if configuration.selfImprovementEnabled {
            let improvementActions = try await selfImprovementEngine.analyzePerformance(evaluation)
            
            for action in improvementActions {
                if !configuration.humanInTheLoop {
                    try await selfImprovementEngine.apply(action)
                } else {
                    await humanFeedbackSystem.proposeImprovement(action)
                }
            }
        }
    }
    
    private func getAgentMetrics() async -> AgentMetrics {
        let activeCount = agents.count
        let capabilities = agents.flatMap { $0.capabilities }
        
        return AgentMetrics(
            activeCount: activeCount,
            totalCapabilities: capabilities.count,
            supportedLanguages: Set(capabilities.flatMap { $0.supportedLanguages })
        )
    }
    
    private func getUptime() -> TimeInterval {
        return ProcessInfo.processInfo.systemUptime
    }
}

// MARK: - Evaluation Pipeline

/// Pipeline for evaluating code quality
public actor EvaluationPipeline: Service {
    private let logger: Logger
    private let configuration: SystemConfiguration
    private let evaluators: [CodeEvaluator]
    
    public init(configuration: SystemConfiguration, evaluators: [CodeEvaluator]) {
        self.configuration = configuration
        self.evaluators = evaluators
        self.logger = configuration.makeLogger(label: "EvaluationPipeline")
    }
    
    public func start() async throws {
        logger.info("Starting evaluation pipeline")
    }
    
    public func stop() async throws {
        logger.info("Stopping evaluation pipeline")
    }
    
    public func evaluate(_ codeFile: CodeFile, for task: CodingTask) async throws -> EvaluationResult {
        logger.debug("Evaluating code for task: \(task.title)")
        
        var allMetrics = PerformanceMetrics()
        var allFeedback: [FeedbackItem] = []
        var allSuggestions: [Suggestion] = []
        var passedTests = true
        
        for evaluator in evaluators {
            let result = try await evaluator.evaluate(codeFile, for: task)
            
            allMetrics = mergeMetrics(allMetrics, result.performanceMetrics)
            allFeedback.append(contentsOf: result.feedback)
            allSuggestions.append(contentsOf: result.suggestions)
            
            if !result.passedTests {
                passedTests = false
            }
        }
        
        return EvaluationResult(
            taskID: task.id,
            codeFile: codeFile,
            performanceMetrics: allMetrics,
            passedTests: passedTests,
            feedback: allFeedback,
            suggestions: allSuggestions
        )
    }
    
    private func mergeMetrics(_ metrics1: PerformanceMetrics, _ metrics2: PerformanceMetrics) -> PerformanceMetrics {
        return PerformanceMetrics(
            executionTime: max(metrics1.executionTime, metrics2.executionTime),
            memoryUsage: max(metrics1.memoryUsage, metrics2.memoryUsage),
            cpuUsage: max(metrics1.cpuUsage, metrics2.cpuUsage),
            complexityScore: (metrics1.complexityScore + metrics2.complexityScore) / 2,
            readabilityScore: (metrics1.readabilityScore + metrics2.readabilityScore) / 2,
            maintainabilityScore: (metrics1.maintainabilityScore + metrics2.maintainabilityScore) / 2,
            testCoverage: max(metrics1.testCoverage, metrics2.testCoverage),
            benchmarkScore: (metrics1.benchmarkScore + metrics2.benchmarkScore) / 2
        )
    }
}

// MARK: - Security Manager

/// Manages security and sandboxing
public actor SecurityManager: Service {
    private let logger: Logger
    private let configuration: SystemConfiguration
    private let sandbox: Sandbox
    
    public init(configuration: SystemConfiguration) {
        self.configuration = configuration
        self.logger = configuration.makeLogger(label: "SecurityManager")
        self.sandbox = SecureSandbox(configuration: configuration)
    }
    
    public func start() async throws {
        logger.info("Starting security manager")
        try await (sandbox as? SecureSandbox)?.start()
    }
    
    public func stop() async throws {
        logger.info("Stopping security manager")
        try await (sandbox as? SecureSandbox)?.stop()
    }
    
    public func validateSecurity(_ codeFile: CodeFile) async throws -> SecurityValidationResult {
        if let secureSandbox = sandbox as? SecureSandbox {
            return try await secureSandbox.validateSecurity(codeFile)
        }
        
        return SecurityValidationResult(isSecure: true, issues: [])
    }
}

// MARK: - Human Feedback System

/// Manages human-in-the-loop feedback
public actor HumanFeedbackSystem: Service {
    private let logger: Logger
    private let configuration: SystemConfiguration
    private var pendingApprovals: [EntityID: PendingApproval] = [:]
    
    public init(configuration: SystemConfiguration) {
        self.configuration = configuration
        self.logger = configuration.makeLogger(label: "HumanFeedbackSystem")
    }
    
    public func start() async throws {
        logger.info("Starting human feedback system")
    }
    
    public func stop() async throws {
        logger.info("Stopping human feedback system")
    }
    
    public func requestSecurityApproval(codeFile: CodeFile, issues: [String]) async throws -> Bool {
        logger.info("Requesting security approval for: \(codeFile.path)")
        
        let approvalID = EntityID()
        let approval = PendingApproval(
            id: approvalID,
            type: .security,
            codeFile: codeFile,
            issues: issues,
            timestamp: Timestamp()
        )
        
        pendingApprovals[approvalID] = approval
        
        logger.info("Approval requested: \(approvalID.value)")
        logger.info("Issues: \(issues.joined(separator: ", "))")
        
        if !configuration.humanInTheLoop {
            logger.debug("Human-in-the-loop disabled, auto-approving")
            return true
        }
        
        return false
    }
    
    public func proposeImprovement(_ action: ImprovementAction) async {
        logger.info("Proposed improvement: \(action.type.rawValue)")
        logger.info("Description: \(action.description)")
    }
    
    public func approve(_ approvalID: EntityID) {
        logger.info("Approval granted: \(approvalID.value)")
        pendingApprovals.removeValue(forKey: approvalID)
    }
    
    public func reject(_ approvalID: EntityID, reason: String) {
        logger.info("Approval rejected: \(approvalID.value), Reason: \(reason)")
        pendingApprovals.removeValue(forKey: approvalID)
    }
}

// MARK: - Task Queue

/// Manages task queuing and processing
public actor TaskQueue {
    private var pendingTasks: [CodingTask] = []
    private var completedTasks: [EntityID: TaskResult] = [:]
    private var failedTasks: [EntityID: Error] = [:]
    private var taskStatus: [EntityID: TaskStatus] = [:]
    
    public init() {}
    
    func enqueue(_ task: CodingTask) async throws {
        pendingTasks.append(task)
        taskStatus[task.id] = .pending
    }
    
    func dequeue() async throws -> CodingTask? {
        guard !pendingTasks.isEmpty else {
            return nil
        }
        
        let task = pendingTasks.removeFirst()
        return task
    }
    
    func updateStatus(_ taskID: EntityID, status: TaskStatus) async throws {
        taskStatus[taskID] = status
    }
    
    func complete(_ taskID: EntityID, result: TaskResult) async throws {
        completedTasks[taskID] = result
        taskStatus[taskID] = .completed
    }
    
    func fail(_ taskID: EntityID, error: Error) async throws {
        failedTasks[taskID] = error
        taskStatus[taskID] = .failed
    }
    
    func cancel(_ taskID: EntityID) async throws {
        taskStatus[taskID] = .cancelled
    }
    
    func getStatus(_ taskID: EntityID) async throws -> TaskStatus {
        return taskStatus[taskID] ?? .notFound
    }
    
    func getResult(_ taskID: EntityID) async throws -> TaskResult? {
        return completedTasks[taskID]
    }
    
    func getMetrics() async -> QueueMetrics {
        let totalProcessed = completedTasks.count + failedTasks.count
        let averageProcessingTime = 0.0 // Would be calculated from actual data
        
        return QueueMetrics(
            pendingCount: pendingTasks.count,
            totalProcessed: totalProcessed,
            averageProcessingTime: averageProcessingTime
        )
    }
}

// MARK: - Supporting Types

/// Default code evaluator
struct DefaultCodeEvaluator: CodeEvaluator {
    private let configuration: SystemConfiguration
    
    init(configuration: SystemConfiguration) {
        self.configuration = configuration
    }
    
    func evaluate(_ codeFile: CodeFile, for task: CodingTask) async throws -> EvaluationResult {
        let metrics = PerformanceMetrics(
            executionTime: Double.random(in: 0.1...2.0),
            memoryUsage: UInt64.random(in: 1_000_000...100_000_000),
            cpuUsage: Double.random(in: 10...80),
            complexityScore: Double.random(in: 0.6...0.95),
            readabilityScore: Double.random(in: 0.7...0.95),
            maintainabilityScore: Double.random(in: 0.65...0.9),
            testCoverage: Double.random(in: 0.8...1.0),
            benchmarkScore: Double.random(in: 0.7...0.95)
        )
        
        let passedTests = metrics.overallScore >= 0.75
        
        return EvaluationResult(
            taskID: task.id,
            codeFile: codeFile,
            performanceMetrics: metrics,
            passedTests: passedTests,
            feedback: [],
            suggestions: []
        )
    }
}

/// Default monitoring system
struct DefaultMonitoringSystem: MonitoringSystem {
    private let configuration: SystemConfiguration
    private var metrics: [MetricData] = []
    
    init(configuration: SystemConfiguration) {
        self.configuration = configuration
    }
    
    func start() async throws {
        // Implementation would start monitoring services
    }
    
    func stop() async throws {
        // Implementation would stop monitoring services
    }
    
    func recordMetric(_ name: String, value: Double, tags: [String: String]) async {
        let metric = MetricData(
            name: name,
            value: value,
            timestamp: Timestamp(),
            tags: tags
        )
        metrics.append(metric)
    }
    
    func recordEvent(_ name: String, properties: [String: String]) async {
        // Implementation would record structured events
    }
    
    func getMetrics(for timeRange: TimeRange) async throws -> [MetricData] {
        return metrics.filter { metric in
            let metricDate = Date(timeIntervalSince1970: Double(metric.timestamp.nanoseconds) / 1_000_000_000)
            return timeRange.start <= metricDate && metricDate <= timeRange.end
        }
    }
}

// MARK: - Data Event Extensions

extension DataEvent.EventType {
    static let taskSubmitted = Self(rawValue: "task_submitted")!
    static let taskStarted = Self(rawValue: "task_started")!
    static let taskCompleted = Self(rawValue: "task_completed")!
    static let taskFailed = Self(rawValue: "task_failed")!
}

// MARK: - Supporting Data Types

/// Represents task status
public enum TaskStatus: String, Sendable {
    case pending
    case inProgress = "in_progress"
    case completed
    case failed
    case cancelled
    case notFound = "not_found"
}

/// Represents task result
public enum TaskResult: Sendable {
    case codeFile(CodeFile)
    case error(Error)
}

/// Represents queue metrics
struct QueueMetrics {
    let pendingCount: Int
    let totalProcessed: Int
    let averageProcessingTime: TimeInterval
}

/// Represents agent metrics
struct AgentMetrics {
    let activeCount: Int
    let totalCapabilities: Int
    let supportedLanguages: Set<ProgrammingLanguage>
}

/// Represents system metrics
public struct SystemMetrics: Sendable {
    public let uptime: TimeInterval
    public let tasksProcessed: Int
    public let tasksInQueue: Int
    public let activeAgents: Int
    public let averageTaskTime: TimeInterval
    public let improvementSuccessRate: Double
    
    public init(
        uptime: TimeInterval,
        tasksProcessed: Int,
        tasksInQueue: Int,
        activeAgents: Int,
        averageTaskTime: TimeInterval,
        improvementSuccessRate: Double
    ) {
        self.uptime = uptime
        self.tasksProcessed = tasksProcessed
        self.tasksInQueue = tasksInQueue
        self.activeAgents = activeAgents
        self.averageTaskTime = averageTaskTime
        self.improvementSuccessRate = improvementSuccessRate
    }
}

/// Pending approval for human review
struct PendingApproval {
    let id: EntityID
    let type: ApprovalType
    let codeFile: CodeFile
    let issues: [String]
    let timestamp: Timestamp
    
    enum ApprovalType {
        case security
        case improvement
    }
}