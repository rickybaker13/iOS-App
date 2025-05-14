//
//  Model.swift
//  iOS-App
//
//  Created by user942277 on 5/3/25.
//
import Foundation

struct Subject: Identifiable, Codable {
    let id: UUID
    var name: String
    var subcategories: [Subcategory]
    
    init(id: UUID = UUID(), name: String, subcategories: [Subcategory] = []) {
        self.id = id
        self.name = name
        self.subcategories = subcategories
    }
}
struct Subcategory: Identifiable, Codable {
    let id: UUID
    var name: String
    
    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
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
