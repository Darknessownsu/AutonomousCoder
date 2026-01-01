//
//  CoreTests.swift
//  AutonomousCoderCoreTests
//
//  Created by Autonomous Coder on 2025-01-01
//  Copyright (c) 2025 Autonomous Coder. All rights reserved.
//

import XCTest
@testable import AutonomousCoderCore

final class CoreTests: XCTestCase {
    
    // MARK: - EntityID Tests
    
    func testEntityIDGeneration() {
        let id1 = EntityID()
        let id2 = EntityID()
        
        XCTAssertNotEqual(id1.value, id2.value)
        XCTAssertEqual(id1.value.count, 36) // UUID string length
    }
    
    func testEntityIDCustomValue() {
        let customValue = "custom-id-123"
        let id = EntityID(customValue)
        
        XCTAssertEqual(id.value, customValue)
    }
    
    func testEntityIDHashable() {
        let id1 = EntityID("test-id")
        let id2 = EntityID("test-id")
        let id3 = EntityID("different-id")
        
        XCTAssertEqual(id1, id2)
        XCTAssertNotEqual(id1, id3)
        
        var set = Set<EntityID>()
        set.insert(id1)
        set.insert(id2)
        set.insert(id3)
        
        XCTAssertEqual(set.count, 2)
    }
    
    // MARK: - Timestamp Tests
    
    func testTimestampGeneration() {
        let timestamp1 = Timestamp()
        Thread.sleep(forTimeInterval: 0.001)
        let timestamp2 = Timestamp()
        
        XCTAssertLessThan(timestamp1.nanoseconds, timestamp2.nanoseconds)
    }
    
    func testTimestampComparison() {
        let timestamp1 = Timestamp(nanoseconds: 100)
        let timestamp2 = Timestamp(nanoseconds: 200)
        let timestamp3 = Timestamp(nanoseconds: 100)
        
        XCTAssertLessThan(timestamp1, timestamp2)
        XCTAssertGreaterThan(timestamp2, timestamp1)
        XCTAssertEqual(timestamp1, timestamp3)
    }
    
    // MARK: - ProgrammingLanguage Tests
    
    func testProgrammingLanguageDecoding() {
        XCTAssertEqual(ProgrammingLanguage(rawValue: "swift"), .swift)
        XCTAssertEqual(ProgrammingLanguage(rawValue: "python"), .python)
        XCTAssertEqual(ProgrammingLanguage(rawValue: "javascript"), .javascript)
        XCTAssertEqual(ProgrammingLanguage(rawValue: "typescript"), .typescript)
        
        let unknown = ProgrammingLanguage(rawValue: "unknown")
        if case .other(let name) = unknown {
            XCTAssertEqual(name, "unknown")
        } else {
            XCTFail("Should decode as .other")
        }
    }
    
    func testProgrammingLanguageFileExtensions() {
        XCTAssertEqual(ProgrammingLanguage.swift.fileExtensions, [".swift"])
        XCTAssertEqual(ProgrammingLanguage.python.fileExtensions, [".py"])
        XCTAssertEqual(ProgrammingLanguage.objectiveC.fileExtensions, [".m", ".h"])
        XCTAssertEqual(ProgrammingLanguage.other("custom").fileExtensions, [])
    }
    
    func testProgrammingLanguageDescription() {
        XCTAssertEqual(ProgrammingLanguage.swift.description, "Swift")
        XCTAssertEqual(ProgrammingLanguage.python.description, "Python")
        XCTAssertEqual(ProgrammingLanguage.other("custom").description, "custom")
    }
    
    // MARK: - CodeFile Tests
    
    func testCodeFileCreation() {
        let codeFile = CodeFile(
            path: "test.swift",
            content: "print(\"Hello, World!\")",
            language: .swift,
            metadata: ["author": "test"]
        )
        
        XCTAssertEqual(codeFile.path, "test.swift")
        XCTAssertEqual(codeFile.content, "print(\"Hello, World!\")")
        XCTAssertEqual(codeFile.language, .swift)
        XCTAssertEqual(codeFile.metadata["author"], "test")
        XCTAssertNotNil(codeFile.createdAt)
        XCTAssertNotNil(codeFile.modifiedAt)
    }
    
    func testCodeFileEquality() {
        let id = EntityID()
        let codeFile1 = CodeFile(
            id: id,
            path: "test.swift",
            content: "print(\"Hello\")",
            language: .swift
        )
        let codeFile2 = CodeFile(
            id: id,
            path: "test.swift",
            content: "print(\"Hello\")",
            language: .swift
        )
        let codeFile3 = CodeFile(
            path: "test.swift",
            content: "print(\"World\")",
            language: .swift
        )
        
        XCTAssertEqual(codeFile1, codeFile2)
        XCTAssertNotEqual(codeFile1, codeFile3)
    }
    
    // MARK: - CodingTask Tests
    
    func testCodingTaskCreation() {
        let task = CodingTask(
            title: "Sort Array",
            description: "Implement bubble sort",
            requirements: [
                Requirement(description: "Sort in ascending order"),
                Requirement(description: "Handle empty arrays", isOptional: true)
            ],
            constraints: [
                Constraint(type: .timeComplexity, description: "O(n²) acceptable")
            ],
            targetLanguage: .python,
            difficulty: .medium,
            tags: ["sorting", "algorithms"]
        )
        
        XCTAssertEqual(task.title, "Sort Array")
        XCTAssertEqual(task.description, "Implement bubble sort")
        XCTAssertEqual(task.targetLanguage, .python)
        XCTAssertEqual(task.difficulty, .medium)
        XCTAssertEqual(task.requirements.count, 2)
        XCTAssertEqual(task.constraints.count, 1)
        XCTAssertEqual(task.tags, ["sorting", "algorithms"])
    }
    
    // MARK: - PerformanceMetrics Tests
    
    func testPerformanceMetricsOverallScore() {
        let metrics = PerformanceMetrics(
            complexityScore: 0.8,
            readabilityScore: 0.9,
            maintainabilityScore: 0.85,
            testCoverage: 0.95,
            benchmarkScore: 0.75
        )
        
        let expectedScore = (0.8 + 0.9 + 0.85 + 0.95 + 0.75) / 5.0
        XCTAssertEqual(metrics.overallScore, expectedScore, accuracy: 0.001)
    }
    
    func testPerformanceMetricsDefaultValues() {
        let metrics = PerformanceMetrics()
        
        XCTAssertEqual(metrics.executionTime, 0)
        XCTAssertEqual(metrics.memoryUsage, 0)
        XCTAssertEqual(metrics.cpuUsage, 0)
        XCTAssertEqual(metrics.complexityScore, 0)
        XCTAssertEqual(metrics.readabilityScore, 0)
        XCTAssertEqual(metrics.maintainabilityScore, 0)
        XCTAssertEqual(metrics.testCoverage, 0)
        XCTAssertEqual(metrics.benchmarkScore, 0)
    }
    
    // MARK: - EvaluationResult Tests
    
    func testEvaluationResultCreation() {
        let taskID = EntityID()
        let codeFile = CodeFile(
            path: "test.py",
            content: "print('test')",
            language: .python
        )
        let metrics = PerformanceMetrics(
            complexityScore: 0.8,
            readabilityScore: 0.9,
            testCoverage: 1.0
        )
        
        let result = EvaluationResult(
            taskID: taskID,
            codeFile: codeFile,
            performanceMetrics: metrics,
            passedTests: true,
            feedback: [
                FeedbackItem(type: .suggestion, message: "Consider using list comprehension")
            ]
        )
        
        XCTAssertEqual(result.taskID, taskID)
        XCTAssertEqual(result.codeFile, codeFile)
        XCTAssertEqual(result.performanceMetrics.overallScore, metrics.overallScore)
        XCTAssertTrue(result.passedTests)
        XCTAssertEqual(result.feedback.count, 1)
    }
    
    // MARK: - ImprovementAction Tests
    
    func testImprovementActionCreation() {
        let action = ImprovementAction(
            type: .codeGenerationStrategy,
            description: "Improve variable naming",
            parameters: ["focus": "naming"],
            expectedOutcome: "Better readability",
            priority: .high
        )
        
        XCTAssertEqual(action.type, .codeGenerationStrategy)
        XCTAssertEqual(action.description, "Improve variable naming")
        XCTAssertEqual(action.parameters["focus"], "naming")
        XCTAssertEqual(action.expectedOutcome, "Better readability")
        XCTAssertEqual(action.priority, .high)
        XCTAssertEqual(action.status, .pending)
        XCTAssertNotNil(action.createdAt)
        XCTAssertNil(action.appliedAt)
    }
    
    // MARK: - LearningExperience Tests
    
    func testLearningExperienceImprovementRatio() {
        let beforeMetrics = PerformanceMetrics(
            complexityScore: 0.5,
            readabilityScore: 0.6,
            maintainabilityScore: 0.55,
            testCoverage: 0.8,
            benchmarkScore: 0.5
        )
        
        let afterMetrics = PerformanceMetrics(
            complexityScore: 0.7,
            readabilityScore: 0.8,
            maintainabilityScore: 0.75,
            testCoverage: 0.9,
            benchmarkScore: 0.7
        )
        
        let experience = LearningExperience(
            taskID: EntityID(),
            actionTaken: ImprovementAction(type: .algorithmOptimization, description: "Optimize algorithm"),
            beforeMetrics: beforeMetrics,
            afterMetrics: afterMetrics,
            success: true
        )
        
        let expectedRatio = (afterMetrics.overallScore - beforeMetrics.overallScore) / beforeMetrics.overallScore
        XCTAssertEqual(experience.improvementRatio, expectedRatio, accuracy: 0.001)
    }
    
    func testLearningExperienceZeroDivision() {
        let beforeMetrics = PerformanceMetrics() // All scores are 0
        let afterMetrics = PerformanceMetrics(
            complexityScore: 0.5,
            readabilityScore: 0.6,
            maintainabilityScore: 0.55,
            testCoverage: 0.8,
            benchmarkScore: 0.5
        )
        
        let experience = LearningExperience(
            taskID: EntityID(),
            actionTaken: ImprovementAction(type: .codeGenerationStrategy, description: "Test"),
            beforeMetrics: beforeMetrics,
            afterMetrics: afterMetrics,
            success: true
        )
        
        XCTAssertEqual(experience.improvementRatio, 0.0)
    }
    
    // MARK: - SystemConfiguration Tests
    
    func testSystemConfigurationDefaults() {
        let config = SystemConfiguration()
        
        XCTAssertEqual(config.maxCodeGenerationTime, 300)
        XCTAssertEqual(config.maxExecutionTime, 60)
        XCTAssertEqual(config.maxMemoryUsage, 1_073_741_824)
        XCTAssertTrue(config.sandboxEnabled)
        XCTAssertTrue(config.selfImprovementEnabled)
        XCTAssertTrue(config.humanInTheLoop)
        XCTAssertEqual(config.loggingLevel, .info)
    }
    
    func testSystemConfigurationLogger() {
        let config = SystemConfiguration()
        let logger = config.makeLogger(label: "test")
        
        XCTAssertEqual(logger.logLevel, .info)
    }
    
    func testSystemConfigurationValidation() throws {
        var config = SystemConfiguration()
        
        // Should not throw with valid config
        XCTAssertNoThrow(try config.validate())
        
        // Test invalid configurations
        config.maxCodeGenerationTime = -1
        XCTAssertThrowsError(try config.validate()) { error in
            if case AutonomousCoderError.configurationError(let message) = error {
                XCTAssertTrue(message.contains("positive"))
            }
        }
    }
    
    // MARK: - Error Tests
    
    func testAutonomousCoderErrorCases() {
        let errors: [AutonomousCoderError] = [
            .invalidState("Invalid state"),
            .resourceNotFound("Resource not found"),
            .permissionDenied("Permission denied"),
            .timeout("Operation timed out"),
            .validationFailed("Validation failed"),
            .executionFailed("Execution failed"),
            .improvementFailed("Improvement failed"),
            .sandboxError("Sandbox error"),
            .networkError("Network error"),
            .configurationError("Configuration error")
        ]
        
        for error in errors {
            switch error {
            case .invalidState(let msg):
                XCTAssertEqual(msg, "Invalid state")
            case .resourceNotFound(let msg):
                XCTAssertEqual(msg, "Resource not found")
            case .permissionDenied(let msg):
                XCTAssertEqual(msg, "Permission denied")
            case .timeout(let msg):
                XCTAssertEqual(msg, "Operation timed out")
            case .validationFailed(let msg):
                XCTAssertEqual(msg, "Validation failed")
            case .executionFailed(let msg):
                XCTAssertEqual(msg, "Execution failed")
            case .improvementFailed(let msg):
                XCTAssertEqual(msg, "Improvement failed")
            case .sandboxError(let msg):
                XCTAssertEqual(msg, "Sandbox error")
            case .networkError(let msg):
                XCTAssertEqual(msg, "Network error")
            case .configurationError(let msg):
                XCTAssertEqual(msg, "Configuration error")
            }
        }
    }
    
    // MARK: - Protocol Conformance Tests
    
    func testAgentProtocol() {
        struct TestAgent: Agent {
            let id = EntityID()
            let name = "TestAgent"
            let capabilities = [
                Capability(name: "Test", description: "Test capability", supportedLanguages: [.swift])
            ]
            
            func canHandle(_ task: CodingTask) -> Bool {
                return task.targetLanguage == .swift
            }
            
            func execute(_ task: CodingTask) async throws -> CodeFile {
                return CodeFile(path: "test.swift", content: "// Test", language: .swift)
            }
        }
        
        let agent = TestAgent()
        let swiftTask = CodingTask(title: "Test", description: "Test", targetLanguage: .swift)
        let pythonTask = CodingTask(title: "Test", description: "Test", targetLanguage: .python)
        
        XCTAssertTrue(agent.canHandle(swiftTask))
        XCTAssertFalse(agent.canHandle(pythonTask))
        XCTAssertEqual(agent.capabilities.count, 1)
    }
    
    func testRepositoryProtocol() async {
        actor TestRepository<T>: Repository where T: Hashable & Codable & Sendable {
            private var storage: [EntityID: T] = [:]
            
            func save(_ item: T) async throws {
                let id = EntityID()
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
        
        let repository = TestRepository<CodeFile>()
        let codeFile = CodeFile(path: "test.swift", content: "test", language: .swift)
        
        do {
            try await repository.save(codeFile)
            let count = try await repository.count()
            XCTAssertEqual(count, 1)
        } catch {
            XCTFail("Repository operations should not fail")
        }
    }
    
    // MARK: - Performance Tests
    
    func testEntityIDGenerationPerformance() {
        measure {
            for _ in 0..<10000 {
                _ = EntityID()
            }
        }
    }
    
    func testTimestampGenerationPerformance() {
        measure {
            for _ in 0..<10000 {
                _ = Timestamp()
            }
        }
    }
}