//
//  SelfImprovement.swift
//  AutonomousCoder
//
//  Created by Autonomous Coder on 2025-01-01
//  Copyright (c) 2025 Autonomous Coder. All rights reserved.
//

import Foundation
import Logging

// MARK: - Self-Improvement Engine

/// Core engine that drives the self-improvement loop
public actor SelfImprovementEngine: SelfImproving {
    private let logger: Logger
    private let configuration: SystemConfiguration
    private let evaluationRepository: any Repository<EvaluationResult>
    private let actionRepository: any Repository<ImprovementAction>
    private let learningRepository: any Repository<LearningExperience>
    private let strategyAnalyzers: [StrategyAnalyzer]
    private let improvementHandlers: [ImprovementHandler]
    private let performanceThreshold: Double
    
    public init(
        configuration: SystemConfiguration,
        evaluationRepository: any Repository<EvaluationResult>,
        actionRepository: any Repository<ImprovementAction>,
        learningRepository: any Repository<LearningExperience>,
        performanceThreshold: Double = 0.05
    ) {
        self.configuration = configuration
        self.evaluationRepository = evaluationRepository
        self.actionRepository = actionRepository
        self.learningRepository = learningRepository
        self.performanceThreshold = performanceThreshold
        self.logger = configuration.makeLogger(label: "SelfImprovementEngine")
        
        self.strategyAnalyzers = [
            CodeGenerationStrategyAnalyzer(),
            AlgorithmOptimizationAnalyzer(),
            ArchitectureRefactoringAnalyzer(),
            TrainingDataEnhancementAnalyzer(),
            ModelParameterTuningAnalyzer(),
            FeedbackIntegrationAnalyzer()
        ]
        
        self.improvementHandlers = [
            CodeGenerationStrategyHandler(),
            AlgorithmOptimizationHandler(),
            ArchitectureRefactoringHandler(),
            TrainingDataEnhancementHandler(),
            ModelParameterTuningHandler(),
            FeedbackIntegrationHandler()
        ]
    }
    
    public func start() async throws {
        logger.info("Starting self-improvement engine")
        
        Task {
            await runContinuousImprovementLoop()
        }
    }
    
    public func stop() async throws {
        logger.info("Stopping self-improvement engine")
    }
    
    public func analyzePerformance(_ evaluation: EvaluationResult) async throws -> [ImprovementAction] {
        logger.debug("Analyzing performance for task: \(evaluation.taskID.value)")
        
        try await evaluationRepository.save(evaluation)
        
        guard configuration.selfImprovementEnabled else {
            logger.debug("Self-improvement is disabled")
            return []
        }
        
        let performanceGap = await calculatePerformanceGap(evaluation)
        
        guard performanceGap > performanceThreshold else {
            logger.debug("Performance within acceptable threshold")
            return []
        }
        
        var actions: [ImprovementAction] = []
        
        for analyzer in strategyAnalyzers {
            if let action = await analyzer.analyze(evaluation, gap: performanceGap) {
                actions.append(action)
                try await actionRepository.save(action)
                logger.debug("Generated improvement action: \(action.type.rawValue)")
            }
        }
        
        return actions.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    public func apply(_ action: ImprovementAction) async throws {
        logger.info("Applying improvement action: \(action.type.rawValue)")
        
        guard let handler = improvementHandlers.first(where: { $0.canHandle(action.type) }) else {
            throw AutonomousCoderError.improvementFailed("No handler found for action type: \(action.type)")
        }
        
        var mutableAction = action
        mutableAction.status = .inProgress
        try await actionRepository.save(mutableAction)
        
        do {
            let beforeMetrics = try await getCurrentPerformanceMetrics()
            try await handler.handle(action)
            let afterMetrics = try await getCurrentPerformanceMetrics()
            
            let success = afterMetrics.overallScore > beforeMetrics.overallScore
            let learningExperience = LearningExperience(
                taskID: action.id,
                actionTaken: action,
                beforeMetrics: beforeMetrics,
                afterMetrics: afterMetrics,
                success: success
            )
            
            try await learningRepository.save(learningExperience)
            
            mutableAction.status = success ? .completed : .failed
            mutableAction.appliedAt = Timestamp()
            try await actionRepository.save(mutableAction)
            
            logger.info("Improvement action completed with success: \(success)")
            
        } catch {
            mutableAction.status = .failed
            try await actionRepository.save(mutableAction)
            throw error
        }
    }
    
    public func getLearningHistory() async throws -> [LearningExperience] {
        return try await learningRepository.findAll()
    }
    
    public func getPendingActions() async throws -> [ImprovementAction] {
        let allActions = try await actionRepository.findAll()
        return allActions.filter { $0.status == .pending }
    }
    
    public func getActionSuccessRate() async throws -> Double {
        let allActions = try await actionRepository.findAll()
        guard !allActions.isEmpty else { return 0.0 }
        
        let successfulActions = allActions.filter { $0.status == .completed }
        return Double(successfulActions.count) / Double(allActions.count)
    }
    
    // MARK: - Private Methods
    
    private func runContinuousImprovementLoop() async {
        logger.info("Starting continuous improvement loop")
        
        while true {
            do {
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                
                let pendingActions = try await getPendingActions()
                
                for action in pendingActions {
                    if configuration.humanInTheLoop {
                        logger.info("Human-in-the-loop enabled, skipping automatic application of action: \(action.id.value)")
                        continue
                    }
                    
                    do {
                        try await apply(action)
                    } catch {
                        logger.error("Failed to apply improvement action: \(error)")
                    }
                }
                
            } catch {
                logger.error("Error in improvement loop: \(error)")
            }
        }
    }
    
    private func calculatePerformanceGap(_ evaluation: EvaluationResult) async -> Double {
        let targets = configuration.performanceTargets
        let metrics = evaluation.performanceMetrics
        
        var gaps: [Double] = []
        
        if metrics.complexityScore < targets.minComplexityScore {
            gaps.append(targets.minComplexityScore - metrics.complexityScore)
        }
        
        if metrics.readabilityScore < targets.minReadabilityScore {
            gaps.append(targets.minReadabilityScore - metrics.readabilityScore)
        }
        
        if metrics.maintainabilityScore < targets.minMaintainabilityScore {
            gaps.append(targets.minMaintainabilityScore - metrics.maintainabilityScore)
        }
        
        if metrics.testCoverage < targets.minTestCoverage {
            gaps.append(targets.minTestCoverage - metrics.testCoverage)
        }
        
        return gaps.max() ?? 0.0
    }
    
    private func getCurrentPerformanceMetrics() async throws -> PerformanceMetrics {
        let recentEvaluations = try await evaluationRepository.findAll()
        
        guard !recentEvaluations.isEmpty else {
            return PerformanceMetrics()
        }
        
        let latestEvaluation = recentEvaluations.max { $0.timestamp < $1.timestamp }!
        return latestEvaluation.performanceMetrics
    }
}

// MARK: - Strategy Analyzers

/// Base protocol for strategy analyzers
protocol StrategyAnalyzer {
    func analyze(_ evaluation: EvaluationResult, gap: Double) async -> ImprovementAction?
}

/// Analyzes code generation strategies
struct CodeGenerationStrategyAnalyzer: StrategyAnalyzer {
    func analyze(_ evaluation: EvaluationResult, gap: Double) async -> ImprovementAction? {
        guard evaluation.performanceMetrics.readabilityScore < 0.7 else {
            return nil
        }
        
        return ImprovementAction(
            type: .codeGenerationStrategy,
            description: "Improve code generation strategy for better readability",
            parameters: [
                "target_readability": "0.8",
                "focus_areas": "naming,comments,structure"
            ],
            expectedOutcome: "Generated code will have better readability and maintainability",
            priority: .high
        )
    }
}

/// Analyzes algorithm optimization opportunities
struct AlgorithmOptimizationAnalyzer: StrategyAnalyzer {
    func analyze(_ evaluation: EvaluationResult, gap: Double) async -> ImprovementAction? {
        guard evaluation.performanceMetrics.executionTime > 30 else {
            return nil
        }
        
        return ImprovementAction(
            type: .algorithmOptimization,
            description: "Optimize algorithm for better performance",
            parameters: [
                "target_execution_time": "15.0",
                "optimization_techniques": "memoization,caching,parallelization"
            ],
            expectedOutcome: "Reduced execution time while maintaining correctness",
            priority: .high
        )
    }
}

/// Analyzes architecture refactoring needs
struct ArchitectureRefactoringAnalyzer: StrategyAnalyzer {
    func analyze(_ evaluation: EvaluationResult, gap: Double) async -> ImprovementAction? {
        guard evaluation.performanceMetrics.maintainabilityScore < 0.6 else {
            return nil
        }
        
        return ImprovementAction(
            type: .architectureRefactoring,
            description: "Refactor architecture for better maintainability",
            parameters: [
                "target_maintainability": "0.8",
                "refactoring_patterns": "separation_of_concerns,single_responsibility"
            ],
            expectedOutcome: "Improved code organization and maintainability",
            priority: .medium
        )
    }
}

/// Analyzes training data enhancement needs
struct TrainingDataEnhancementAnalyzer: StrategyAnalyzer {
    func analyze(_ evaluation: EvaluationResult, gap: Double) async -> ImprovementAction? {
        guard evaluation.passedTests == false else {
            return nil
        }
        
        return ImprovementAction(
            type: .trainingDataEnhancement,
            description: "Enhance training data with similar examples",
            parameters: [
                "data_augmentation": "true",
                "focus_areas": "test_cases,edge_cases,error_handling"
            ],
            expectedOutcome: "Better test coverage and error handling",
            priority: .high
        )
    }
}

/// Analyzes model parameter tuning needs
struct ModelParameterTuningAnalyzer: StrategyAnalyzer {
    func analyze(_ evaluation: EvaluationResult, gap: Double) async -> ImprovementAction? {
        guard gap > 0.1 else {
            return nil
        }
        
        return ImprovementAction(
            type: .modelParameterTuning,
            description: "Fine-tune model parameters for better performance",
            parameters: [
                "tuning_method": "grid_search",
                "parameters": "temperature,max_tokens,top_p"
            ],
            expectedOutcome: "Improved generation quality and performance",
            priority: .medium
        )
    }
}

/// Analyzes feedback integration needs
struct FeedbackIntegrationAnalyzer: StrategyAnalyzer {
    func analyze(_ evaluation: EvaluationResult, gap: Double) async -> ImprovementAction? {
        guard !evaluation.feedback.isEmpty else {
            return nil
        }
        
        let criticalFeedback = evaluation.feedback.filter { $0.severity == .critical || $0.severity == .high }
        
        guard !criticalFeedback.isEmpty else {
            return nil
        }
        
        return ImprovementAction(
            type: .feedbackIntegration,
            description: "Integrate feedback from evaluation into generation process",
            parameters: [
                "feedback_count": "\(criticalFeedback.count)",
                "feedback_categories": criticalFeedback.map { $0.type.rawValue }.joined(separator: ",")
            ],
            expectedOutcome: "Better alignment with quality standards",
            priority: .critical
        )
    }
}

// MARK: - Improvement Handlers

/// Base protocol for improvement handlers
protocol ImprovementHandler {
    func canHandle(_ type: ImprovementAction.ActionType) -> Bool
    func handle(_ action: ImprovementAction) async throws
}

/// Handles code generation strategy improvements
struct CodeGenerationStrategyHandler: ImprovementHandler {
    func canHandle(_ type: ImprovementAction.ActionType) -> Bool {
        return type == .codeGenerationStrategy
    }
    
    func handle(_ action: ImprovementAction) async throws {
        logger.info("Applying code generation strategy improvement")
        
        guard let targetReadability = action.parameters["target_readability"],
              let focusAreas = action.parameters["focus_areas"] else {
            throw AutonomousCoderError.improvementFailed("Missing required parameters")
        }
        
        logger.info("Targeting readability: \(targetReadability), Focus areas: \(focusAreas)")
        
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms simulation
    }
}

/// Handles algorithm optimization improvements
struct AlgorithmOptimizationHandler: ImprovementHandler {
    func canHandle(_ type: ImprovementAction.ActionType) -> Bool {
        return type == .algorithmOptimization
    }
    
    func handle(_ action: ImprovementAction) async throws {
        logger.info("Applying algorithm optimization improvement")
        
        guard let targetTime = action.parameters["target_execution_time"],
              let techniques = action.parameters["optimization_techniques"] else {
            throw AutonomousCoderError.improvementFailed("Missing required parameters")
        }
        
        logger.info("Targeting execution time: \(targetTime), Techniques: \(techniques)")
        
        try await Task.sleep(nanoseconds: 150_000_000) // 150ms simulation
    }
}

/// Handles architecture refactoring improvements
struct ArchitectureRefactoringHandler: ImprovementHandler {
    func canHandle(_ type: ImprovementAction.ActionType) -> Bool {
        return type == .architectureRefactoring
    }
    
    func handle(_ action: ImprovementAction) async throws {
        logger.info("Applying architecture refactoring improvement")
        
        guard let targetMaintainability = action.parameters["target_maintainability"],
              let patterns = action.parameters["refactoring_patterns"] else {
            throw AutonomousCoderError.improvementFailed("Missing required parameters")
        }
        
        logger.info("Targeting maintainability: \(targetMaintainability), Patterns: \(patterns)")
        
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms simulation
    }
}

/// Handles training data enhancement improvements
struct TrainingDataEnhancementHandler: ImprovementHandler {
    func canHandle(_ type: ImprovementAction.ActionType) -> Bool {
        return type == .trainingDataEnhancement
    }
    
    func handle(_ action: ImprovementAction) async throws {
        logger.info("Applying training data enhancement improvement")
        
        guard let dataAugmentation = action.parameters["data_augmentation"],
              let focusAreas = action.parameters["focus_areas"] else {
            throw AutonomousCoderError.improvementFailed("Missing required parameters")
        }
        
        logger.info("Data augmentation: \(dataAugmentation), Focus areas: \(focusAreas)")
        
        try await Task.sleep(nanoseconds: 300_000_000) // 300ms simulation
    }
}

/// Handles model parameter tuning improvements
struct ModelParameterTuningHandler: ImprovementHandler {
    func canHandle(_ type: ImprovementAction.ActionType) -> Bool {
        return type == .modelParameterTuning
    }
    
    func handle(_ action: ImprovementAction) async throws {
        logger.info("Applying model parameter tuning improvement")
        
        guard let tuningMethod = action.parameters["tuning_method"],
              let parameters = action.parameters["parameters"] else {
            throw AutonomousCoderError.improvementFailed("Missing required parameters")
        }
        
        logger.info("Tuning method: \(tuningMethod), Parameters: \(parameters)")
        
        try await Task.sleep(nanoseconds: 250_000_000) // 250ms simulation
    }
}

/// Handles feedback integration improvements
struct FeedbackIntegrationHandler: ImprovementHandler {
    func canHandle(_ type: ImprovementAction.ActionType) -> Bool {
        return type == .feedbackIntegration
    }
    
    func handle(_ action: ImprovementAction) async throws {
        logger.info("Applying feedback integration improvement")
        
        guard let feedbackCount = action.parameters["feedback_count"],
              let categories = action.parameters["feedback_categories"] else {
            throw AutonomousCoderError.improvementFailed("Missing required parameters")
        }
        
        logger.info("Feedback count: \(feedbackCount), Categories: \(categories)")
        
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms simulation
    }
}

// MARK: - Extensions

extension SelfImprovementEngine {
    /// Gets improvement statistics
    public func getStatistics() async throws -> ImprovementStatistics {
        let allActions = try await actionRepository.findAll()
        let allExperiences = try await learningRepository.findAll()
        
        let successfulActions = allActions.filter { $0.status == .completed }
        let failedActions = allActions.filter { $0.status == .failed }
        
        let averageImprovement = allExperiences.map { $0.improvementRatio }.reduce(0, +) / Double(allExperiences.count)
        
        return ImprovementStatistics(
            totalActions: allActions.count,
            successfulActions: successfulActions.count,
            failedActions: failedActions.count,
            averageImprovement: averageImprovement,
            totalExperiences: allExperiences.count
        )
    }
}

/// Statistics for self-improvement
public struct ImprovementStatistics: Hashable, Codable, Sendable {
    public let totalActions: Int
    public let successfulActions: Int
    public let failedActions: Int
    public let averageImprovement: Double
    public let totalExperiences: Int
    
    public var successRate: Double {
        guard totalActions > 0 else { return 0 }
        return Double(successfulActions) / Double(totalActions)
    }
    
    public init(
        totalActions: Int,
        successfulActions: Int,
        failedActions: Int,
        averageImprovement: Double,
        totalExperiences: Int
    ) {
        self.totalActions = totalActions
        self.successfulActions = successfulActions
        self.failedActions = failedActions
        self.averageImprovement = averageImprovement
        self.totalExperiences = totalExperiences
    }
}

// MARK: - Logger Extensions

private var logger: Logger {
    Logger(label: "ImprovementHandler")
}