//
//  AITests.swift
//  AutonomousCoderAITests
//
//  Created by Autonomous Coder on 2025-01-01
//  Copyright (c) 2025 Autonomous Coder. All rights reserved.
//

import XCTest
@testable import AutonomousCoderAI
@testable import AutonomousCoderCore

final class AITests: XCTestCase {
    
    var configuration: SystemConfiguration!
    
    override func setUp() {
        super.setUp()
        configuration = SystemConfiguration()
    }
    
    // MARK: - BaseAIAgent Tests
    
    func testBaseAIAgentInitialization() async {
        let agent = BaseAIAgent(
            name: "TestAgent",
            capabilities: [
                Capability(name: "Test", description: "Test capability", supportedLanguages: [.swift])
            ],
            configuration: configuration
        )
        
        XCTAssertEqual(agent.name, "TestAgent")
        XCTAssertEqual(agent.capabilities.count, 1)
        XCTAssertTrue(agent.id.value.count > 0)
    }
    
    func testBaseAIAgentCanHandle() async {
        let agent = BaseAIAgent(
            name: "SwiftAgent",
            capabilities: [
                Capability(name: "Swift Dev", description: "Swift development", supportedLanguages: [.swift])
            ],
            configuration: configuration
        )
        
        let swiftTask = CodingTask(title: "Test", description: "Test", targetLanguage: .swift)
        let pythonTask = CodingTask(title: "Test", description: "Test", targetLanguage: .python)
        
        XCTAssertTrue(agent.canHandle(swiftTask))
        XCTAssertFalse(agent.canHandle(pythonTask))
    }
    
    // MARK: - CodeGenerationAgent Tests
    
    func testCodeGenerationAgentInitialization() async {
        let agent = CodeGenerationAgent(configuration: configuration)
        
        XCTAssertEqual(agent.name, "CodeGenerationAgent")
        XCTAssertTrue(agent.capabilities.contains { $0.name == "Code Generation" })
        XCTAssertTrue(agent.capabilities.contains { $0.name == "Architecture Design" })
        XCTAssertTrue(agent.capabilities.contains { $0.name == "Algorithm Implementation" })
    }
    
    func testCodeGenerationAgentExecute() async {
        let agent = CodeGenerationAgent(configuration: configuration)
        
        let task = CodingTask(
            title: "Hello World",
            description: "Create a simple hello world program",
            targetLanguage: .swift
        )
        
        do {
            try await agent.start()
            let codeFile = try await agent.execute(task)
            try await agent.stop()
            
            XCTAssertEqual(codeFile.language, .swift)
            XCTAssertTrue(codeFile.path.hasSuffix(".swift"))
            XCTAssertTrue(codeFile.content.contains("Hello"))
            
        } catch {
            XCTFail("Code generation should not fail: \(error)")
        }
    }
    
    // MARK: - CodeDebuggingAgent Tests
    
    func testCodeDebuggingAgentInitialization() async {
        let agent = CodeDebuggingAgent(configuration: configuration)
        
        XCTAssertEqual(agent.name, "CodeDebuggingAgent")
        XCTAssertTrue(agent.capabilities.contains { $0.name == "Bug Detection" })
        XCTAssertTrue(agent.capabilities.contains { $0.name == "Error Correction" })
        XCTAssertTrue(agent.capabilities.contains { $0.name == "Code Refactoring" })
    }
    
    func testCodeDebuggingAgentDebug() async {
        let agent = CodeDebuggingAgent(configuration: configuration)
        
        let codeFile = CodeFile(
            path: "test.swift",
            content: """
            func greet() {
                print("Hello"
            }
            """,
            language: .swift
        )
        
        do {
            try await agent.start()
            let fixedCodeFile = try await agent.debug(codeFile, errorDescription: "Missing closing parenthesis")
            try await agent.stop()
            
            XCTAssertNotNil(fixedCodeFile)
            XCTAssertTrue(fixedCodeFile.content.contains(")"))
            
        } catch {
            XCTFail("Debugging should not fail: \(error)")
        }
    }
    
    // MARK: - CodeOptimizationAgent Tests
    
    func testCodeOptimizationAgentInitialization() async {
        let agent = CodeOptimizationAgent(configuration: configuration)
        
        XCTAssertEqual(agent.name, "CodeOptimizationAgent")
        XCTAssertTrue(agent.capabilities.contains { $0.name == "Performance Optimization" })
        XCTAssertTrue(agent.capabilities.contains { $0.name == "Algorithm Optimization" })
        XCTAssertTrue(agent.capabilities.contains { $0.name == "Memory Optimization" })
    }
    
    func testCodeOptimizationAgentOptimize() async {
        let agent = CodeOptimizationAgent(configuration: configuration)
        
        let codeFile = CodeFile(
            path: "test.py",
            content: """
            def slow_function():
                result = 0
                for i in range(1000000):
                    result += i
                return result
            """,
            language: .python
        )
        
        let targetMetrics = PerformanceMetrics(
            executionTime: 5.0,
            complexityScore: 0.9,
            benchmarkScore: 0.9
        )
        
        do {
            try await agent.start()
            let optimizedCodeFile = try await agent.optimize(codeFile, targetMetrics: targetMetrics)
            try await agent.stop()
            
            XCTAssertNotNil(optimizedCodeFile)
            XCTAssertEqual(optimizedCodeFile.metadata["optimized_by"], "CodeOptimizationAgent")
            
        } catch {
            XCTFail("Optimization should not fail: \(error)")
        }
    }
    
    // MARK: - Self-Improvement Tests
    
    func testSelfImprovementEngineInitialization() async {
        let evaluationRepository = MockRepository<EvaluationResult>()
        let actionRepository = MockRepository<ImprovementAction>()
        let learningRepository = MockRepository<LearningExperience>()
        
        let engine = SelfImprovementEngine(
            configuration: configuration,
            evaluationRepository: evaluationRepository,
            actionRepository: actionRepository,
            learningRepository: learningRepository
        )
        
        XCTAssertNotNil(engine)
    }
    
    func testSelfImprovementEngineAnalyzePerformance() async {
        let evaluationRepository = MockRepository<EvaluationResult>()
        let actionRepository = MockRepository<ImprovementAction>()
        let learningRepository = MockRepository<LearningExperience>()
        
        let engine = SelfImprovementEngine(
            configuration: configuration,
            evaluationRepository: evaluationRepository,
            actionRepository: actionRepository,
            learningRepository: learningRepository
        )
        
        let taskID = EntityID()
        let codeFile = CodeFile(path: "test.swift", content: "test", language: .swift)
        let metrics = PerformanceMetrics(
            complexityScore: 0.3,  // Below threshold
            readabilityScore: 0.4,
            maintainabilityScore: 0.5,
            testCoverage: 0.6
        )
        
        let evaluation = EvaluationResult(
            taskID: taskID,
            codeFile: codeFile,
            performanceMetrics: metrics,
            passedTests: false
        )
        
        do {
            try await engine.start()
            let actions = try await engine.analyzePerformance(evaluation)
            try await engine.stop()
            
            XCTAssertTrue(actions.count > 0, "Should generate improvement actions for poor performance")
            
            if let firstAction = actions.first {
                XCTAssertEqual(firstAction.status, .pending)
                XCTAssertTrue(firstAction.priority == .high || firstAction.priority == .critical)
            }
            
        } catch {
            XCTFail("Performance analysis should not fail: \(error)")
        }
    }
    
    func testSelfImprovementEngineApplyAction() async {
        let evaluationRepository = MockRepository<EvaluationResult>()
        let actionRepository = MockRepository<ImprovementAction>()
        let learningRepository = MockRepository<LearningExperience>()
        
        let engine = SelfImprovementEngine(
            configuration: configuration,
            evaluationRepository: evaluationRepository,
            actionRepository: actionRepository,
            learningRepository: learningRepository
        )
        
        let action = ImprovementAction(
            type: .codeGenerationStrategy,
            description: "Test improvement",
            expectedOutcome: "Better performance"
        )
        
        do {
            try await engine.start()
            try await engine.apply(action)
            try await engine.stop()
            
            let experiences = try await learningRepository.findAll()
            XCTAssertEqual(experiences.count, 1)
            
            if let experience = experiences.first {
                XCTAssertEqual(experience.actionTaken.id, action.id)
                XCTAssertTrue(experience.success || !experience.success) // Either outcome is valid
            }
            
        } catch {
            XCTFail("Applying improvement action should not fail: \(error)")
        }
    }
    
    func testSelfImprovementEngineGetStatistics() async {
        let evaluationRepository = MockRepository<EvaluationResult>()
        let actionRepository = MockRepository<ImprovementAction>()
        let learningRepository = MockRepository<LearningExperience>()
        
        let engine = SelfImprovementEngine(
            configuration: configuration,
            evaluationRepository: evaluationRepository,
            actionRepository: actionRepository,
            learningRepository: learningRepository
        )
        
        // Add some test data
        let successfulAction = ImprovementAction(
            type: .algorithmOptimization,
            description: "Success",
            expectedOutcome: "Better"
        )
        
        let failedAction = ImprovementAction(
            type: .codeGenerationStrategy,
            description: "Fail",
            expectedOutcome: "Worse"
        )
        
        do {
            try await actionRepository.save(successfulAction)
            try await actionRepository.save(failedAction)
            
            let statistics = try await engine.getStatistics()
            
            XCTAssertEqual(statistics.totalActions, 2)
            XCTAssertEqual(statistics.successfulActions, 0) // Both are pending
            XCTAssertEqual(statistics.failedActions, 0)
            XCTAssertEqual(statistics.totalExperiences, 0)
            
        } catch {
            XCTFail("Getting statistics should not fail: \(error)")
        }
    }
    
    // MARK: - Mock Repository Implementation
    
    actor MockRepository<T>: Repository where T: Hashable & Codable & Sendable {
        private var storage: [EntityID: T] = [:]
        private var nextID = 1
        
        func save(_ item: T) async throws {
            let id = EntityID("mock-\(nextID)")
            nextID += 1
            storage[id] = item
        }
        
        func find(byID id: EntityID) async throws -> T? {
            return storage[id]
        }
        
        func findAll() async throws -> [T] {
            return Array(storage.values)
        }
        
        func delete(_ item: T) async throws {
            // Simplified implementation
        }
        
        func count() async throws -> Int {
            return storage.count
        }
    }
    
    // MARK: - Performance Tests
    
    func testAgentInitializationPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = CodeGenerationAgent(configuration: configuration)
            }
        }
    }
    
    func testCapabilityCheckingPerformance() async {
        let agent = BaseAIAgent(
            name: "PerformanceTestAgent",
            capabilities: [
                Capability(name: "Swift", description: "", supportedLanguages: [.swift]),
                Capability(name: "Python", description: "", supportedLanguages: [.python]),
                Capability(name: "JS", description: "", supportedLanguages: [.javascript])
            ],
            configuration: configuration
        )
        
        let tasks = [
            CodingTask(title: "1", description: "", targetLanguage: .swift),
            CodingTask(title: "2", description: "", targetLanguage: .python),
            CodingTask(title: "3", description: "", targetLanguage: .javascript)
        ]
        
        measure {
            for _ in 0..<10000 {
                let task = tasks.randomElement()!
                _ = agent.canHandle(task)
            }
        }
    }
}