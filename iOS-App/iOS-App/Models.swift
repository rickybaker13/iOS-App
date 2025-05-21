//
//  Models.swift
//  iOS-App
//
//  Created by user942277 on 5/3/25.
//
import Foundation

enum AppModels {
    struct Subject: Identifiable, Codable, Hashable {
        let id: UUID
        var name: String
        var subcategories: [Subcategory]
        
        init(id: UUID = UUID(), name: String, subcategories: [Subcategory] = []) {
            self.id = id
            self.name = name
            self.subcategories = subcategories
        }
        
        // Implement Hashable
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: Subject, rhs: Subject) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    struct Subcategory: Identifiable, Codable, Hashable {
        let id: UUID
        var name: String
        
        init(id: UUID = UUID(), name: String) {
            self.id = id
            self.name = name
        }
        
        // Implement Hashable
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: Subcategory, rhs: Subcategory) -> Bool {
            lhs.id == rhs.id
        }
    }

    struct Lecture: Identifiable, Codable {
        let id: UUID
        var title: String
        var subject: Subject
        var subcategory: Subcategory
        var recordingURL: URL
        var createdAt: Date
        var transcript: String?
        
        init(id: UUID = UUID(), title: String, subject: Subject, subcategory: Subcategory, recordingURL: URL, createdAt: Date = Date(), transcript: String? = nil) {
            self.id = id
            self.title = title
            self.subject = subject
            self.subcategory = subcategory
            self.recordingURL = recordingURL
            self.createdAt = createdAt
            self.transcript = transcript
        }
    }

    struct Assignment: Identifiable, Codable {
        let id: UUID
        var title: String
        var subject: Subject
        var dueDate: Date
        var isCompleted: Bool
        var notes: String?
        
        init(id: UUID = UUID(), title: String, subject: Subject, dueDate: Date, isCompleted: Bool = false, notes: String? = nil) {
            self.id = id
            self.title = title
            self.subject = subject
            self.dueDate = dueDate
            self.isCompleted = isCompleted
            self.notes = notes
        }
    }
}
