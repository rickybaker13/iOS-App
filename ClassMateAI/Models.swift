import Foundation

public struct Subject: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var icon: String
    public var lectures: [Lecture]
    
    public init(id: UUID = UUID(), name: String, icon: String, lectures: [Lecture] = []) {
        self.id = id
        self.name = name
        self.icon = icon
        self.lectures = lectures
    }
    
    // Implement Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Subject, rhs: Subject) -> Bool {
        lhs.id == rhs.id
    }
}

public struct Lecture: Identifiable, Codable {
    public let id: UUID
    public var title: String
    public var date: Date
    public var duration: TimeInterval
    public var recordingURL: URL?
    public var notes: String
    public var outline: String
    public var subjectId: UUID
    
    public init(id: UUID = UUID(), title: String, date: Date = Date(), duration: TimeInterval = 0, recordingURL: URL? = nil, notes: String = "", outline: String = "", subjectId: UUID) {
        self.id = id
        self.title = title
        self.date = date
        self.duration = duration
        self.recordingURL = recordingURL
        self.notes = notes
        self.outline = outline
        self.subjectId = subjectId
    }
}

struct ImportantInfo: Identifiable, Codable {
    let id: UUID
    let lectureId: UUID
    let text: String
    let type: InfoType
    let timestamp: Date
    let source: String
    
    enum InfoType: String, Codable {
        case homework
        case test
        case quiz
        case custom
    }
}

struct CustomTrigger: Identifiable, Codable {
    let id: UUID
    let phrase: String
    let description: String
    var isActive: Bool
} 