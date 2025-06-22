import Foundation
import SwiftUI

class DataManager: ObservableObject {
    @Published var subjects: [Subject] = []
    @Published var customTriggers: [CustomTrigger] = []
    @Published var importantInfo: [ImportantInfo] = []
    private let subjectsKey = "savedSubjects"
    
    init() {
        print("DataManager: Initializing")
        loadData()
        loadCustomTriggers()
        loadImportantInfo()
    }
    
    private func loadData() {
        print("DataManager: Loading subjects")
        if let data = UserDefaults.standard.data(forKey: subjectsKey),
           let decoded = try? JSONDecoder().decode([Subject].self, from: data) {
            subjects = decoded
            print("DataManager: Successfully loaded \(subjects.count) subjects")
        } else {
            print("DataManager: No saved subjects found, loading defaults")
            // Load default subjects if none exist
            subjects = [
                Subject(name: "Computer Science", icon: "laptopcomputer"),
                Subject(name: "Mathematics", icon: "function"),
                Subject(name: "Physics", icon: "atom"),
                Subject(name: "Chemistry", icon: "flask.fill")
            ]
            saveSubjects()
        }
    }
    
    func saveSubjects() {
        print("DataManager: Saving subjects")
        if let encoded = try? JSONEncoder().encode(subjects) {
            UserDefaults.standard.set(encoded, forKey: subjectsKey)
            print("DataManager: Successfully saved \(subjects.count) subjects")
        } else {
            print("DataManager: Failed to encode subjects")
        }
    }
    
    func addSubject(_ subject: Subject) {
        subjects.append(subject)
        saveSubjects()
    }
    
    func addLecture(_ lecture: Lecture, to subject: Subject) {
        print("DataManager: Adding lecture '\(lecture.title)' to subject '\(subject.name)'")
        if let index = subjects.firstIndex(where: { $0.id == subject.id }) {
            subjects[index].lectures.append(lecture)
            print("DataManager: Successfully added lecture")
            saveData()
        } else {
            print("DataManager: Failed to find subject with id \(subject.id)")
        }
    }
    
    func updateLecture(_ lecture: Lecture, notes: String, outline: String) {
        print("DataManager: Updating lecture '\(lecture.title)'")
        if let subjectIndex = subjects.firstIndex(where: { $0.id == lecture.subjectId }),
           let lectureIndex = subjects[subjectIndex].lectures.firstIndex(where: { $0.id == lecture.id }) {
            var updatedLecture = lecture
            updatedLecture.notes = notes
            updatedLecture.outline = outline
            subjects[subjectIndex].lectures[lectureIndex] = updatedLecture
            print("DataManager: Successfully updated lecture")
            saveData()
        } else {
            print("DataManager: Failed to find lecture or subject")
        }
    }
    
    func deleteLecture(_ lecture: Lecture, from subject: Subject) {
        print("DataManager: Deleting lecture '\(lecture.title)' from subject '\(subject.name)'")
        if let subjectIndex = subjects.firstIndex(where: { $0.id == subject.id }) {
            subjects[subjectIndex].lectures.removeAll { $0.id == lecture.id }
            print("DataManager: Successfully deleted lecture")
            saveData()
        } else {
            print("DataManager: Failed to find subject with id \(subject.id)")
        }
    }
    
    private func saveData() {
        saveSubjects()
    }
    
    // MARK: - Custom Triggers
    
    func addTrigger(phrase: String, description: String) {
        let trigger = CustomTrigger(
            id: UUID(),
            phrase: phrase,
            description: description,
            isActive: true
        )
        customTriggers.append(trigger)
        saveCustomTriggers()
    }
    
    func updateTrigger(_ trigger: CustomTrigger, isActive: Bool) {
        if let index = customTriggers.firstIndex(where: { $0.id == trigger.id }) {
            var updatedTrigger = trigger
            updatedTrigger.isActive = isActive
            customTriggers[index] = updatedTrigger
            saveCustomTriggers()
        }
    }
    
    func deleteTriggers(at offsets: IndexSet) {
        customTriggers.remove(atOffsets: offsets)
        saveCustomTriggers()
    }
    
    private func saveCustomTriggers() {
        if let encoded = try? JSONEncoder().encode(customTriggers) {
            UserDefaults.standard.set(encoded, forKey: "customTriggers")
        }
    }
    
    private func loadCustomTriggers() {
        if let data = UserDefaults.standard.data(forKey: "customTriggers"),
           let decoded = try? JSONDecoder().decode([CustomTrigger].self, from: data) {
            customTriggers = decoded
        }
    }
    
    // MARK: - Important Information
    
    func addImportantInfo(lectureId: UUID, text: String, type: ImportantInfo.InfoType, source: String) {
        let info = ImportantInfo(
            id: UUID(),
            lectureId: lectureId,
            text: text,
            type: type,
            timestamp: Date(),
            source: source
        )
        importantInfo.append(info)
        saveImportantInfo()
    }
    
    func getImportantInfo(for lectureId: UUID) -> [ImportantInfo] {
        return importantInfo.filter { $0.lectureId == lectureId }
    }
    
    private func saveImportantInfo() {
        if let encoded = try? JSONEncoder().encode(importantInfo) {
            UserDefaults.standard.set(encoded, forKey: "importantInfo")
        }
    }
    
    private func loadImportantInfo() {
        if let data = UserDefaults.standard.data(forKey: "importantInfo"),
           let decoded = try? JSONDecoder().decode([ImportantInfo].self, from: data) {
            importantInfo = decoded
        }
    }
} 