import Foundation
import SwiftUI

struct AssignmentState: Codable {
    var isCompleted: Bool = false
    var savedForLater: Bool = false
    var isRemoved: Bool = false
    var notes: String? = nil
}

class DataManager: ObservableObject {
    @Published var subjects: [Subject] = []
    @Published var customTriggers: [CustomTrigger] = []
    @Published var importantInfo: [ImportantInfo] = []
    @Published var canvasCourses: [CanvasCourse] = []
    @Published var canvasPlannerItems: [CanvasPlannerItem] = []
    @Published var canvasAssignmentsByCourse: [Int: [CanvasAssignment]] = [:]
    @Published var canvasLastSync: Date?
    @Published var canvasRemindersEnabled: Bool = false
    @Published var courseResources: [CourseResource] = []
    @Published var lectureResources: [LectureResource] = []
    @Published private(set) var hiddenCanvasCourseIds: Set<Int> = []
    @Published private(set) var assignmentStatesByCourse: [Int: [Int: AssignmentState]] = [:]
    
    private let subjectsKey = "savedSubjects"
    private let canvasCoursesKey = "canvasCourses"
    private let canvasPlannerKey = "canvasPlannerItems"
    private let canvasAssignmentsKey = "canvasAssignmentsByCourse"
    private let canvasLastSyncKey = "canvasLastSync"
    private let canvasRemindersKey = "canvasRemindersEnabled"
    private let courseResourcesKey = "courseResources"
    private let lectureResourcesKey = "lectureResources"
    private let hiddenCoursesKey = "hiddenCanvasCourseIds"
    private let assignmentStatesKey = "canvasAssignmentStates"
    
    init() {
        print("DataManager: Initializing")
        loadData()
        loadCustomTriggers()
        loadImportantInfo()
        loadCanvasData()
        loadCourseResources()
        print("DataManager: Initialization complete")
        debugPrintSubjects()
    }
    
    private func loadData() {
        print("DataManager: Loading subjects")
        if let data = UserDefaults.standard.data(forKey: subjectsKey),
           let decoded = try? JSONDecoder().decode([Subject].self, from: data) {
            subjects = decoded
            print("DataManager: Successfully loaded \(subjects.count) subjects")
            for subject in subjects {
                print("DataManager: - \(subject.name) (ID: \(subject.id)) with \(subject.lectures.count) lectures")
            }
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
        debugPrintSubjects()
        
        do {
            let encoded = try JSONEncoder().encode(subjects)
            UserDefaults.standard.set(encoded, forKey: subjectsKey)
            print("DataManager: Successfully saved \(subjects.count) subjects")
        } catch {
            print("DataManager: Failed to encode subjects: \(error)")
        }
    }
    
    func addSubject(_ subject: Subject) {
        subjects.append(subject)
        saveSubjects()
    }
    
    func addLecture(_ lecture: Lecture, to subject: Subject) {
        print("DataManager: Adding lecture '\(lecture.title)' to subject '\(subject.name)'")
        print("DataManager: Subject ID: \(subject.id), Lecture Subject ID: \(lecture.subjectId)")
        print("DataManager: Available subjects: \(subjects.map { "\($0.name) (ID: \($0.id))" })")
        
        if let index = subjects.firstIndex(where: { $0.id == subject.id }) {
            subjects[index].lectures.append(lecture)
            print("DataManager: Successfully added lecture to subject at index \(index)")
            saveSubjects()
        } else {
            print("DataManager: Failed to find subject with id \(subject.id)")
            print("DataManager: Available subject IDs: \(subjects.map { $0.id })")
        }
    }
    
    func updateLecture(_ lecture: Lecture, notes: String, outline: String) {
        print("DataManager: Updating lecture '\(lecture.title)'")
        print("DataManager: New notes length: \(notes.count)")
        print("DataManager: New outline length: \(outline.count)")
        print("DataManager: Looking for subject with ID: \(lecture.subjectId)")
        print("DataManager: Available subjects: \(subjects.map { "\($0.name) (ID: \($0.id))" })")
        
        if let subjectIndex = subjects.firstIndex(where: { $0.id == lecture.subjectId }) {
            print("DataManager: Found subject at index \(subjectIndex)")
            print("DataManager: Subject has \(subjects[subjectIndex].lectures.count) lectures")
            
            if let lectureIndex = subjects[subjectIndex].lectures.firstIndex(where: { $0.id == lecture.id }) {
                print("DataManager: Found lecture at index \(lectureIndex)")
                var updatedLecture = lecture
                updatedLecture.notes = notes
                updatedLecture.outline = outline
                subjects[subjectIndex].lectures[lectureIndex] = updatedLecture
                print("DataManager: Successfully updated lecture")
                print("DataManager: Updated lecture notes length: \(subjects[subjectIndex].lectures[lectureIndex].notes.count)")
                saveData()
                
                // Force UI update
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                    print("DataManager: Sent objectWillChange notification")
                }
            } else {
                print("DataManager: Failed to find lecture with ID \(lecture.id)")
                print("DataManager: Available lecture IDs: \(subjects[subjectIndex].lectures.map { $0.id })")
            }
        } else {
            print("DataManager: Failed to find subject with id \(lecture.subjectId)")
            print("DataManager: Available subject IDs: \(subjects.map { $0.id })")
        }
    }
    
    func deleteLecture(_ lecture: Lecture, from subject: Subject) {
        print("DataManager: Deleting lecture '\(lecture.title)' from subject '\(subject.name)'")
        if let subjectIndex = subjects.firstIndex(where: { $0.id == subject.id }) {
            subjects[subjectIndex].lectures.removeAll { $0.id == lecture.id }
            print("DataManager: Successfully deleted lecture")
            saveData()
            objectWillChange.send()
        } else {
            print("DataManager: Failed to find subject with id \(subject.id)")
        }
    }
    
    func deleteLecture(_ lecture: Lecture) {
        print("DataManager: Deleting lecture '\(lecture.title)'")
        for (subjectIndex, subject) in subjects.enumerated() {
            if let lectureIndex = subject.lectures.firstIndex(where: { $0.id == lecture.id }) {
                subjects[subjectIndex].lectures.remove(at: lectureIndex)
                print("DataManager: Successfully deleted lecture from subject '\(subject.name)'")
                saveData()
                objectWillChange.send()
                return
            }
        }
        print("DataManager: Failed to find lecture to delete")
    }
    
    func deleteNotes(for lecture: Lecture) {
        print("DataManager: Deleting notes for lecture '\(lecture.title)'")
        if let subjectIndex = subjects.firstIndex(where: { $0.id == lecture.subjectId }) {
            if let lectureIndex = subjects[subjectIndex].lectures.firstIndex(where: { $0.id == lecture.id }) {
                subjects[subjectIndex].lectures[lectureIndex].notes = ""
                print("DataManager: Successfully deleted notes")
                saveData()
                objectWillChange.send()
            } else {
                print("DataManager: Failed to find lecture")
            }
        } else {
            print("DataManager: Failed to find subject")
        }
    }
    
    func deleteOutline(for lecture: Lecture) {
        print("DataManager: Deleting outline for lecture '\(lecture.title)'")
        if let subjectIndex = subjects.firstIndex(where: { $0.id == lecture.subjectId }) {
            if let lectureIndex = subjects[subjectIndex].lectures.firstIndex(where: { $0.id == lecture.id }) {
                subjects[subjectIndex].lectures[lectureIndex].outline = ""
                print("DataManager: Successfully deleted outline")
                saveData()
                objectWillChange.send()
            } else {
                print("DataManager: Failed to find lecture")
            }
        } else {
            print("DataManager: Failed to find subject")
        }
    }
    
    func updateNotes(for lecture: Lecture, notes: String) {
        print("DataManager: Updating notes for lecture '\(lecture.title)'")
        if let subjectIndex = subjects.firstIndex(where: { $0.id == lecture.subjectId }) {
            if let lectureIndex = subjects[subjectIndex].lectures.firstIndex(where: { $0.id == lecture.id }) {
                subjects[subjectIndex].lectures[lectureIndex].notes = notes
                print("DataManager: Successfully updated notes")
                saveData()
                objectWillChange.send()
            } else {
                print("DataManager: Failed to find lecture")
            }
        } else {
            print("DataManager: Failed to find subject")
        }
    }
    
    func updateNotesWithAttributedData(for lecture: Lecture, notes: String, attributedData: Data?) {
        print("DataManager: Updating notes with attributed data for lecture '\(lecture.title)'")
        if let subjectIndex = subjects.firstIndex(where: { $0.id == lecture.subjectId }) {
            if let lectureIndex = subjects[subjectIndex].lectures.firstIndex(where: { $0.id == lecture.id }) {
                subjects[subjectIndex].lectures[lectureIndex].notes = notes
                subjects[subjectIndex].lectures[lectureIndex].notesAttributedData = attributedData
                print("DataManager: Successfully updated notes with attributed data")
                saveData()
                objectWillChange.send()
            } else {
                print("DataManager: Failed to find lecture")
            }
        } else {
            print("DataManager: Failed to find subject")
        }
    }
    
    func updateNotesWithTimestamps(for lecture: Lecture, notes: String, timestamps: [NotesTimestamp]?) {
        print("DataManager: Updating notes with timestamps for lecture '\(lecture.title)'")
        if let subjectIndex = subjects.firstIndex(where: { $0.id == lecture.subjectId }) {
            if let lectureIndex = subjects[subjectIndex].lectures.firstIndex(where: { $0.id == lecture.id }) {
                subjects[subjectIndex].lectures[lectureIndex].notes = notes
                subjects[subjectIndex].lectures[lectureIndex].notesTimestamps = timestamps
                print("DataManager: Successfully updated notes with timestamps")
                saveData()
                objectWillChange.send()
            } else {
                print("DataManager: Failed to find lecture")
            }
        } else {
            print("DataManager: Failed to find subject")
        }
    }
    
    func updateOutline(for lecture: Lecture, outline: String) {
        print("DataManager: Updating outline for lecture '\(lecture.title)'")
        if let subjectIndex = subjects.firstIndex(where: { $0.id == lecture.subjectId }) {
            if let lectureIndex = subjects[subjectIndex].lectures.firstIndex(where: { $0.id == lecture.id }) {
                subjects[subjectIndex].lectures[lectureIndex].outline = outline
                print("DataManager: Successfully updated outline")
                saveData()
                objectWillChange.send()
            } else {
                print("DataManager: Failed to find lecture")
            }
        } else {
            print("DataManager: Failed to find subject")
        }
    }
    
    func updateOutlineWithAttributedData(for lecture: Lecture, outline: String, attributedData: Data?) {
        print("DataManager: Updating outline with attributed data for lecture '\(lecture.title)'")
        if let subjectIndex = subjects.firstIndex(where: { $0.id == lecture.subjectId }) {
            if let lectureIndex = subjects[subjectIndex].lectures.firstIndex(where: { $0.id == lecture.id }) {
                subjects[subjectIndex].lectures[lectureIndex].outline = outline
                subjects[subjectIndex].lectures[lectureIndex].outlineAttributedData = attributedData
                print("DataManager: Successfully updated outline with attributed data")
                saveData()
                objectWillChange.send()
            } else {
                print("DataManager: Failed to find lecture")
            }
        } else {
            print("DataManager: Failed to find subject")
        }
    }
    
    func addLectureImages(_ images: [LectureImage], to lectureId: UUID) {
        guard !images.isEmpty else { return }
        guard let indices = findLectureIndices(for: lectureId) else {
            print("DataManager: Failed to find lecture for adding images")
            return
        }
        
        var lecture = subjects[indices.subjectIndex].lectures[indices.lectureIndex]
        var existingImages = lecture.lectureImages ?? []
        var existingIds = Set(existingImages.map { $0.id })
        
        for image in images where !existingIds.contains(image.id) {
            existingImages.append(image)
            existingIds.insert(image.id)
        }
        
        lecture.lectureImages = existingImages
        subjects[indices.subjectIndex].lectures[indices.lectureIndex] = lecture
        saveData()
        objectWillChange.send()
        print("DataManager: Added \(images.count) lecture image(s) to lecture \(lectureId)")
    }
    
    func removeLectureImage(_ image: LectureImage) {
        guard let indices = findLectureIndices(for: image.lectureId) else {
            print("DataManager: Failed to find lecture for removing image")
            return
        }
        
        var lecture = subjects[indices.subjectIndex].lectures[indices.lectureIndex]
        lecture.lectureImages = (lecture.lectureImages ?? []).filter { $0.id != image.id }
        subjects[indices.subjectIndex].lectures[indices.lectureIndex] = lecture
        saveData()
        objectWillChange.send()
        print("DataManager: Removed lecture image \(image.id) from lecture \(image.lectureId)")
    }
    
    func setLectureImages(_ images: [LectureImage], for lectureId: UUID) {
        guard let indices = findLectureIndices(for: lectureId) else {
            print("DataManager: Failed to find lecture for setting images")
            return
        }
        
        subjects[indices.subjectIndex].lectures[indices.lectureIndex].lectureImages = images
        saveData()
        objectWillChange.send()
        print("DataManager: Set \(images.count) images for lecture \(lectureId)")
    }
    
    func getLectureImages(for lectureId: UUID) -> [LectureImage] {
        guard let indices = findLectureIndices(for: lectureId) else {
            return []
        }
        let images = subjects[indices.subjectIndex].lectures[indices.lectureIndex].lectureImages ?? []
        return images
    }

    func appendQuestion(_ question: ImageQuestion, to imageId: UUID, lectureId: UUID) {
        guard let indices = findLectureIndices(for: lectureId) else {
            print("DataManager: Failed to find lecture for adding question to image")
            return
        }

        var lecture = subjects[indices.subjectIndex].lectures[indices.lectureIndex]
        guard var lectureImages = lecture.lectureImages,
              let imageIndex = lectureImages.firstIndex(where: { $0.id == imageId }) else {
            print("DataManager: Failed to find lecture image for question append")
            return
        }

        var updatedQuestions = lectureImages[imageIndex].questions
        updatedQuestions.append(question)
        lectureImages[imageIndex] = lectureImages[imageIndex].updating(questions: updatedQuestions)
        lecture.lectureImages = lectureImages
        subjects[indices.subjectIndex].lectures[indices.lectureIndex] = lecture
        saveData()
        objectWillChange.send()
        print("DataManager: Appended question to image \(imageId)")
    }
    
    func moveLecture(_ lecture: Lecture, to targetSubject: Subject) {
        print("DataManager: Moving lecture '\(lecture.title)' to subject '\(targetSubject.name)'")
        
        // First, remove the lecture from its current subject
        var foundLecture: Lecture?
        var sourceSubjectIndex: Int?
        
        for (subjectIndex, subject) in subjects.enumerated() {
            if let lectureIndex = subject.lectures.firstIndex(where: { $0.id == lecture.id }) {
                foundLecture = subjects[subjectIndex].lectures.remove(at: lectureIndex)
                sourceSubjectIndex = subjectIndex
                print("DataManager: Found and removed lecture from subject '\(subject.name)' at index \(subjectIndex)")
                break
            }
        }
        
        guard let lectureToMove = foundLecture else {
            print("DataManager: Failed to find lecture to move")
            return
        }
        
        // Update the lecture's subject ID
        var updatedLecture = lectureToMove
        updatedLecture.subjectId = targetSubject.id
        
        // Add to target subject
        if let targetIndex = subjects.firstIndex(where: { $0.id == targetSubject.id }) {
            subjects[targetIndex].lectures.append(updatedLecture)
            print("DataManager: Successfully moved lecture to subject '\(targetSubject.name)' at index \(targetIndex)")
            saveData()
            
            // Force UI update
            objectWillChange.send()
        } else {
            print("DataManager: Failed to find target subject")
            // Restore the lecture to its original position
            if let sourceIndex = sourceSubjectIndex {
                subjects[sourceIndex].lectures.append(lectureToMove)
                print("DataManager: Restored lecture to original position")
            }
        }
    }
    
    private func saveData() {
        saveSubjects()
    }
    
    private func findLectureIndices(for lectureId: UUID) -> (subjectIndex: Int, lectureIndex: Int)? {
        for (subjectIndex, subject) in subjects.enumerated() {
            if let lectureIndex = subject.lectures.firstIndex(where: { $0.id == lectureId }) {
                return (subjectIndex, lectureIndex)
            }
        }
        return nil
    }
    
    func lectureExists(_ lectureId: UUID) -> Bool {
        return findLectureIndices(for: lectureId) != nil
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
    
    func debugPrintSubjects() {
        print("DataManager: Current subjects state:")
        for subject in subjects {
            print("  - \(subject.name) (ID: \(subject.id)) with \(subject.lectures.count) lectures")
            for lecture in subject.lectures {
                print("    * \(lecture.title) (ID: \(lecture.id), Subject ID: \(lecture.subjectId))")
            }
        }
    }
    
    // MARK: - Testing and Debugging
    
    func clearAllData() {
        print("DataManager: Clearing all data")
        subjects = []
        customTriggers = []
        importantInfo = []
        canvasCourses = []
        canvasPlannerItems = []
        canvasAssignmentsByCourse = [:]
        hiddenCanvasCourseIds = []
        assignmentStatesByCourse = [:]
        canvasLastSync = nil
        courseResources = []
        lectureResources = []
        lectureResources = []
        UserDefaults.standard.removeObject(forKey: subjectsKey)
        UserDefaults.standard.removeObject(forKey: "customTriggers")
        UserDefaults.standard.removeObject(forKey: "importantInfo")
        UserDefaults.standard.removeObject(forKey: canvasAssignmentsKey)
        UserDefaults.standard.removeObject(forKey: canvasCoursesKey)
        UserDefaults.standard.removeObject(forKey: canvasPlannerKey)
        UserDefaults.standard.removeObject(forKey: canvasLastSyncKey)
        UserDefaults.standard.removeObject(forKey: canvasRemindersKey)
        UserDefaults.standard.removeObject(forKey: courseResourcesKey)
        UserDefaults.standard.removeObject(forKey: lectureResourcesKey)
        UserDefaults.standard.removeObject(forKey: hiddenCoursesKey)
        UserDefaults.standard.removeObject(forKey: assignmentStatesKey)
        ResourceStorageService.shared.clearAllResources()
        print("DataManager: All data cleared")
    }
    
    func reloadData() {
        print("DataManager: Reloading data")
        loadData()
        loadCustomTriggers()
        loadImportantInfo()
        loadCanvasData()
        loadCourseResources()
        loadLectureResources()
        debugPrintSubjects()
    }
    
    // MARK: - Canvas Data
    
    func setCanvasCourses(_ courses: [CanvasCourse]) {
        canvasCourses = courses.sorted { $0.name < $1.name }
        if let encoded = try? JSONEncoder().encode(canvasCourses) {
            UserDefaults.standard.set(encoded, forKey: canvasCoursesKey)
        }
        objectWillChange.send()
    }
    
    func setCanvasPlannerItems(_ items: [CanvasPlannerItem]) {
        canvasPlannerItems = items.sorted { (lhs, rhs) in
            switch (lhs.dueAt, rhs.dueAt) {
            case let (l?, r?):
                return l < r
            case (nil, _?):
                return false
            case (_?, nil):
                return true
            default:
                return lhs.title < rhs.title
            }
        }
        if let encoded = try? JSONEncoder().encode(canvasPlannerItems) {
            UserDefaults.standard.set(encoded, forKey: canvasPlannerKey)
        }
        objectWillChange.send()
    }
    
    func updateCanvasLastSync(_ date: Date?) {
        canvasLastSync = date
        UserDefaults.standard.set(date, forKey: canvasLastSyncKey)
        objectWillChange.send()
    }
    
    func setCanvasRemindersEnabled(_ enabled: Bool) {
        canvasRemindersEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: canvasRemindersKey)
    }
    
    func setCanvasAssignments(_ assignments: [CanvasAssignment], for courseId: Int) {
        canvasAssignmentsByCourse[courseId] = assignments
        saveCanvasAssignments()
        objectWillChange.send()
    }
    
    func getCanvasAssignments(for courseId: Int) -> [CanvasAssignment] {
        canvasAssignmentsByCourse[courseId] ?? []
    }
    
    private func loadCanvasData() {
        if let data = UserDefaults.standard.data(forKey: canvasCoursesKey),
           let decoded = try? JSONDecoder().decode([CanvasCourse].self, from: data) {
            canvasCourses = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: canvasPlannerKey),
           let decoded = try? JSONDecoder().decode([CanvasPlannerItem].self, from: data) {
            canvasPlannerItems = decoded
        }
        
        if let date = UserDefaults.standard.object(forKey: canvasLastSyncKey) as? Date {
            canvasLastSync = date
        }
        
        if UserDefaults.standard.object(forKey: canvasRemindersKey) != nil {
            canvasRemindersEnabled = UserDefaults.standard.bool(forKey: canvasRemindersKey)
        }
        
        if let data = UserDefaults.standard.data(forKey: canvasAssignmentsKey),
           let decoded = try? JSONDecoder().decode([Int: [CanvasAssignment]].self, from: data) {
            canvasAssignmentsByCourse = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: hiddenCoursesKey),
           let decoded = try? JSONDecoder().decode([Int].self, from: data) {
            hiddenCanvasCourseIds = Set(decoded)
        }
        
        if let data = UserDefaults.standard.data(forKey: assignmentStatesKey),
           let decoded = try? JSONDecoder().decode([Int: [Int: AssignmentState]].self, from: data) {
            assignmentStatesByCourse = decoded
        }
    }
    
    private func saveCanvasAssignments() {
        if let encoded = try? JSONEncoder().encode(canvasAssignmentsByCourse) {
            UserDefaults.standard.set(encoded, forKey: canvasAssignmentsKey)
        }
    }
    
    // MARK: - Course Resources
    
    func addCourseResource(_ resource: CourseResource) {
        courseResources.append(resource)
        saveCourseResources()
        objectWillChange.send()
    }
    
    func updateCourseResource(_ resource: CourseResource) {
        guard let index = courseResources.firstIndex(where: { $0.id == resource.id }) else { return }
        courseResources[index] = resource
        saveCourseResources()
        objectWillChange.send()
    }
    
    func deleteCourseResource(_ resource: CourseResource) {
        courseResources.removeAll { $0.id == resource.id }
        saveCourseResources()
        ResourceStorageService.shared.deleteResourceFiles(for: resource)
        objectWillChange.send()
    }
    
    func resources(for courseId: Int) -> [CourseResource] {
        courseResources.filter { $0.courseId == courseId }
    }
    
    func resources(forAssignment assignmentId: Int) -> [CourseResource] {
        courseResources.filter { $0.assignmentId == assignmentId }
    }
    
    func resource(withId id: UUID) -> CourseResource? {
        courseResources.first { $0.id == id }
    }
    
    private func saveCourseResources() {
        if let encoded = try? JSONEncoder().encode(courseResources) {
            UserDefaults.standard.set(encoded, forKey: courseResourcesKey)
        }
    }
    
    private func loadCourseResources() {
        if let data = UserDefaults.standard.data(forKey: courseResourcesKey),
           let decoded = try? JSONDecoder().decode([CourseResource].self, from: data) {
            courseResources = decoded
        }
    }
    
    func addLectureResource(_ resource: LectureResource) {
        lectureResources.append(resource)
        saveLectureResources()
        objectWillChange.send()
    }
    
    func deleteLectureResource(_ resource: LectureResource) {
        lectureResources.removeAll { $0.id == resource.id }
        saveLectureResources()
        ResourceStorageService.shared.deleteLectureResourceFiles(for: resource)
        objectWillChange.send()
    }
    
    func lectureResources(for lectureId: UUID) -> [LectureResource] {
        lectureResources.filter { $0.lectureId == lectureId }
    }
    
    private func saveLectureResources() {
        if let encoded = try? JSONEncoder().encode(lectureResources) {
            UserDefaults.standard.set(encoded, forKey: lectureResourcesKey)
        }
    }
    
    private func loadLectureResources() {
        if let data = UserDefaults.standard.data(forKey: lectureResourcesKey),
           let decoded = try? JSONDecoder().decode([LectureResource].self, from: data) {
            lectureResources = decoded
        }
    }
    
    // MARK: - Canvas Course Visibility
    
    func isCourseHidden(_ courseId: Int) -> Bool {
        hiddenCanvasCourseIds.contains(courseId)
    }
    
    func setCourseHidden(_ courseId: Int, hidden: Bool) {
        if hidden {
            hiddenCanvasCourseIds.insert(courseId)
        } else {
            hiddenCanvasCourseIds.remove(courseId)
        }
        saveHiddenCourses()
        objectWillChange.send()
    }
    
    private func saveHiddenCourses() {
        let ids = Array(hiddenCanvasCourseIds)
        if let encoded = try? JSONEncoder().encode(ids) {
            UserDefaults.standard.set(encoded, forKey: hiddenCoursesKey)
        }
    }
    
    // MARK: - Assignment States
    
    func assignmentState(for courseId: Int, assignmentId: Int) -> AssignmentState? {
        assignmentStatesByCourse[courseId]?[assignmentId]
    }
    
    func toggleAssignmentCompletion(courseId: Int, assignmentId: Int) {
        updateAssignmentState(courseId: courseId, assignmentId: assignmentId) { state in
            state.isCompleted.toggle()
            if state.isCompleted {
                state.savedForLater = false
            }
        }
    }
    
    func toggleAssignmentSavedForLater(courseId: Int, assignmentId: Int) {
        updateAssignmentState(courseId: courseId, assignmentId: assignmentId) { state in
            state.savedForLater.toggle()
            if state.savedForLater {
                state.isCompleted = false
            }
        }
    }
    
    func removeAssignment(courseId: Int, assignmentId: Int) {
        updateAssignmentState(courseId: courseId, assignmentId: assignmentId) { state in
            state.isRemoved = true
        }
    }
    
    func restoreAssignment(courseId: Int, assignmentId: Int) {
        updateAssignmentState(courseId: courseId, assignmentId: assignmentId) { state in
            state.isRemoved = false
        }
    }
    
    func updateAssignmentNotes(courseId: Int, assignmentId: Int, notes: String) {
        updateAssignmentState(courseId: courseId, assignmentId: assignmentId) { state in
            state.notes = notes
        }
    }
    
    private func updateAssignmentState(courseId: Int, assignmentId: Int, update: (inout AssignmentState) -> Void) {
        var courseStates = assignmentStatesByCourse[courseId] ?? [:]
        var state = courseStates[assignmentId] ?? AssignmentState()
        update(&state)
        courseStates[assignmentId] = state
        assignmentStatesByCourse[courseId] = courseStates
        saveAssignmentStates()
        objectWillChange.send()
    }
    
    private func saveAssignmentStates() {
        if let encoded = try? JSONEncoder().encode(assignmentStatesByCourse) {
            UserDefaults.standard.set(encoded, forKey: assignmentStatesKey)
        }
    }
} 