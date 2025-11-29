import Foundation

struct CanvasCourse: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let courseCode: String
    let termName: String?
    let startAt: Date?
    let endAt: Date?
    let teacherName: String?
    let currentScore: Double?
    let currentGrade: String?
    
    var displayGrade: String {
        if let currentGrade {
            return currentGrade
        }
        if let score = currentScore {
            return String(format: "%.1f%%", score)
        }
        return "—"
    }
}

struct CanvasPlannerItem: Identifiable, Codable, Hashable {
    enum ItemType: String, Codable {
        case assignment
        case quiz
        case discussion
        case announcement
        case other
        
        init(rawValue: String?) {
            switch rawValue?.lowercased() {
            case "assignment":
                self = .assignment
            case "quiz":
                self = .quiz
            case "discussion_topic":
                self = .discussion
            case "announcement":
                self = .announcement
            default:
                self = .other
            }
        }
        
        var displayName: String {
            switch self {
            case .assignment: return "Assignment"
            case .quiz: return "Quiz"
            case .discussion: return "Discussion"
            case .announcement: return "Announcement"
            case .other: return "Activity"
            }
        }
        
        var iconName: String {
            switch self {
            case .assignment: return "doc.text"
            case .quiz: return "checkmark.circle"
            case .discussion: return "text.bubble"
            case .announcement: return "megaphone"
            case .other: return "calendar"
            }
        }
    }
    
    let id: String
    let courseId: Int
    let courseName: String?
    let title: String
    let type: ItemType
    let dueAt: Date?
    let htmlURL: URL?
    let pointsPossible: Double?
    let submitted: Bool
    
    var isOverdue: Bool {
        guard let dueAt else { return false }
        return dueAt < Date()
    }
}

struct CanvasAssignmentAttachment: Identifiable, Codable, Hashable {
    let id: Int
    let displayName: String?
    let contentType: String?
    let url: URL?
}

struct CanvasAssignment: Identifiable, Codable, Hashable {
    let id: Int
    let courseId: Int
    let name: String
    let descriptionHTML: String?
    let dueAt: Date?
    let pointsPossible: Double?
    let htmlURL: URL?
    let submissionTypes: [String]
    let attachments: [CanvasAssignmentAttachment]
    let externalToolUrl: URL?
    let updatedAt: Date?
    
    var descriptionText: String {
        guard let descriptionHTML, !descriptionHTML.isEmpty else { return "" }
        return CanvasAssignment.plainText(fromHTML: descriptionHTML)
    }
    
    var googleSlidesLinks: [URL] {
        var links: [URL] = []
        attachments.forEach { attachment in
            if let url = attachment.url, url.absoluteString.contains("docs.google.com/presentation") {
                links.append(url)
            }
        }
        for link in CanvasAssignment.extractLinks(from: descriptionHTML) where link.absoluteString.contains("docs.google.com/presentation") {
            if !links.contains(link) {
                links.append(link)
            }
        }
        if let externalToolUrl, externalToolUrl.absoluteString.contains("docs.google.com/presentation"),
           !links.contains(externalToolUrl) {
            links.append(externalToolUrl)
        }
        return links
    }
    
    var resourceLinks: [URL] {
        var links = Set<URL>()
        attachments.compactMap { $0.url }.forEach { links.insert($0) }
        CanvasAssignment.extractLinks(from: descriptionHTML).forEach { links.insert($0) }
        if let externalToolUrl {
            links.insert(externalToolUrl)
        }
        return Array(links)
    }
    
    private static func extractLinks(from html: String?) -> [URL] {
        guard let html, !html.isEmpty else { return [] }
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let nsRange = NSRange(html.startIndex..<html.endIndex, in: html)
        let matches = detector?.matches(in: html, options: [], range: nsRange) ?? []
        return matches.compactMap { match in
            guard let range = Range(match.range, in: html) else { return nil }
            return URL(string: String(html[range]))
        }
    }
    
    private static func plainText(fromHTML html: String) -> String {
        var text = html
        let replacements: [(pattern: String, replacement: String)] = [
            ("(?i)<br\\s*/?>", "\n"),
            ("(?i)</p>", "\n"),
            ("(?is)<style.*?</style>", ""),
            ("(?is)<script.*?</script>", ""),
            ("(?is)<iframe.*?</iframe>", ""),
            ("<[^>]+>", " ")
        ]
        
        for item in replacements {
            text = text.replacingOccurrences(of: item.pattern, with: item.replacement, options: .regularExpression)
        }
        
        // Decode common HTML entities
        let entities: [String: String] = [
            "&nbsp;": " ",
            "&amp;": "&",
            "&quot;": "\"",
            "&lt;": "<",
            "&gt;": ">",
            "&rsquo;": "'",
            "&lsquo;": "'",
            "&rdquo;": "\u{201D}",
            "&ldquo;": "\u{201C}",
            "&ndash;": "–",
            "&mdash;": "—"
        ]
        
        for (entity, replacement) in entities {
            text = text.replacingOccurrences(of: entity, with: replacement)
        }
        
        text = text.replacingOccurrences(of: "\\s+\n", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression)
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return text
    }
}
