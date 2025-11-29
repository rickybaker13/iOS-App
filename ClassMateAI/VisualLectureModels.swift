import Foundation
import UIKit

// MARK: - Visual Lecture Models
public struct LectureImage: Identifiable, Codable {
    public let id: UUID
    public let lectureId: UUID
    public let timestamp: Date
    public let imageFileName: String
    public let description: String?
    public let aiAnalysis: String?
    public let questions: [ImageQuestion]
    
    public init(
        id: UUID = UUID(),
        lectureId: UUID,
        timestamp: Date = Date(),
        imageFileName: String,
        description: String? = nil,
        aiAnalysis: String? = nil,
        questions: [ImageQuestion] = []
    ) {
        self.id = id
        self.lectureId = lectureId
        self.timestamp = timestamp
        self.imageFileName = imageFileName
        self.description = description
        self.aiAnalysis = aiAnalysis
        self.questions = questions
    }
}

public extension LectureImage {
    func updating(
        description: String? = nil,
        aiAnalysis: String?? = nil,
        questions: [ImageQuestion]? = nil
    ) -> LectureImage {
        LectureImage(
            id: id,
            lectureId: lectureId,
            timestamp: timestamp,
            imageFileName: imageFileName,
            description: description ?? self.description,
            aiAnalysis: aiAnalysis ?? self.aiAnalysis,
            questions: questions ?? self.questions
        )
    }
}

public struct ImageQuestion: Identifiable, Codable {
    public let id: UUID
    public let question: String
    public let answer: String
    public let timestamp: Date
    
    public init(id: UUID = UUID(), question: String, answer: String, timestamp: Date = Date()) {
        self.id = id
        self.question = question
        self.answer = answer
        self.timestamp = timestamp
    }
}

// MARK: - Storage Preferences
public enum StoragePreference: String, CaseIterable, Codable {
    case device = "device"
    case cloud = "cloud"
    
    public var displayName: String {
        switch self {
        case .device:
            return "Device Storage"
        case .cloud:
            return "iCloud Storage"
        }
    }
}

// MARK: - Visual Analysis Request
struct VisualAnalysisRequest {
    let image: UIImage
    let question: String
    let lectureContext: String?
    
    init(image: UIImage, question: String, lectureContext: String? = nil) {
        self.image = image
        self.question = question
        self.lectureContext = lectureContext
    }
} 