//
//  TaskCreatorView.swift
//  AutonomousCoder
//
//  Created by Autonomous Coder on 2025-01-01
//  Copyright (c) 2025 Autonomous Coder. All rights reserved.
//

import SwiftUI

struct TaskCreatorView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedLanguage = ProgrammingLanguage.swift
    @State private var difficulty = DifficultyLevel.medium
    @State private var requirements: [String] = []
    @State private var newRequirement = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Create New Task")
                .font(.largeTitle)
                .bold()
            
            // Basic Information
            GroupBox("Basic Information") {
                VStack(spacing: 12) {
                    TextField("Task Title", text: $title)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                    
                    HStack {
                        Picker("Language", selection: $selectedLanguage) {
                            ForEach(ProgrammingLanguage.allCases, id: \\.self) { language in
                                Text(language.description).tag(language)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        Picker("Difficulty", selection: $difficulty) {
                            ForEach(DifficultyLevel.allCases, id: \\.self) { level in
                                Text(level.rawValue.capitalized).tag(level)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding()
            }
            
            // Requirements
            GroupBox("Requirements") {
                VStack(spacing: 12) {
                    HStack {
                        TextField("Add requirement", text: $newRequirement)
                            .textFieldStyle(.roundedBorder)
                        
                        Button(action: addRequirement) {
                            Image(systemName: "plus")
                        }
                        .disabled(newRequirement.isEmpty)
                    }
                    
                    if !requirements.isEmpty {
                        List {
                            ForEach(requirements.indices, id: \\.self) { index in
                                HStack {
                                    Text("• \(requirements[index])")
                                    Spacer()
                                    Button(action: { removeRequirement(at: index) }) {
                                        Image(systemName: "minus.circle")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.borderless)
                                }
                            }
                            .onDelete(perform: removeRequirements)
                        }
                        .frame(height: 120)
                    }
                }
                .padding()
            }
            
            // Constraints
            GroupBox("Constraints") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Performance Targets:")
                        .font(.headline)
                    
                    HStack {
                        Text("Max Execution Time:")
                        TextField("seconds", value: .constant(30), formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Text("Max Memory Usage:")
                        TextField("MB", value: .constant(512), formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
                }
                .padding()
            }
            
            Spacer()
            
            // Action Buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button(action: submitTask) {
                    Label("Create Task", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
        }
        .padding()
        .frame(width: 600, height: 700)
    }
    
    private var isValid: Bool {
        !title.isEmpty && !description.isEmpty
    }
    
    private func addRequirement() {
        guard !newRequirement.isEmpty else { return }
        requirements.append(newRequirement)
        newRequirement = ""
    }
    
    private func removeRequirement(at index: Int) {
        requirements.remove(at: index)
    }
    
    private func removeRequirements(at offsets: IndexSet) {
        requirements.remove(atOffsets: offsets)
    }
    
    private func submitTask() {
        let task = CodingTask(
            title: title,
            description: description,
            requirements: requirements.map { Requirement(description: $0) },
            targetLanguage: selectedLanguage,
            difficulty: difficulty
        )
        
        Task {
            await appState.submitTask(task)
            await MainActor.run {
                dismiss()
            }
        }
    }
}