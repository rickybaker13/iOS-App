import Foundation

actor CanvasAPIClient {
    private let baseURL: URL
    private let accessToken: String
    private let decoder: JSONDecoder
    
    init(
        baseURL: URL = Config.canvasBaseURL,
        accessToken: String = Config.canvasAccessToken
    ) {
        self.baseURL = baseURL
        self.accessToken = accessToken
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    func fetchCourses(limit: Int = 50) async throws -> [CanvasCourse] {
        var components = URLComponents(url: baseURL.appendingPathComponent("courses"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "per_page", value: "\(limit)"),
            URLQueryItem(name: "enrollment_type[]", value: "student"),
            URLQueryItem(name: "state[]", value: "available"),
            URLQueryItem(name: "include[]", value: "total_scores"),
            URLQueryItem(name: "include[]", value: "teachers"),
            URLQueryItem(name: "include[]", value: "enrollments"),
            URLQueryItem(name: "enrollment_state", value: "active")
        ]
        
        let data = try await performRequest(url: components.url!)
        let responses = try decoder.decode([CourseResponse].self, from: data)
        return responses.map { $0.asCanvasCourse }
    }
    
    func fetchPlannerItems(daysAhead: Int = 21) async throws -> [CanvasPlannerItem] {
        let start = ISO8601DateFormatter().string(from: Date())
        let end = ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .day, value: daysAhead, to: Date()) ?? Date())
        
        var components = URLComponents(url: baseURL.appendingPathComponent("planner/items"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "start_date", value: start),
            URLQueryItem(name: "end_date", value: end)
        ]
        
        let data = try await performRequest(url: components.url!)
        let responses = try decoder.decode([PlannerItemResponse].self, from: data)
        return responses.compactMap { $0.asPlannerItem }
    }
    
    func fetchAssignments(for courseId: Int, includePastDue: Bool = false, limit: Int = 50) async throws -> [CanvasAssignment] {
        var components = URLComponents(url: baseURL.appendingPathComponent("courses/\(courseId)/assignments"), resolvingAgainstBaseURL: false)!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "per_page", value: "\(limit)"),
            URLQueryItem(name: "order_by", value: "due_at"),
            URLQueryItem(name: "include[]", value: "submission_types"),
            URLQueryItem(name: "include[]", value: "external_tool_tag_attributes"),
            URLQueryItem(name: "include[]", value: "attachments")
        ]
        components.queryItems = queryItems
        
        let data = try await performRequest(url: components.url!)
        let responses = try decoder.decode([AssignmentResponse].self, from: data)
        return responses.map { $0.asCanvasAssignment(courseId: courseId) }
    }
    
    private func performRequest(url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CanvasAPIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw CanvasAPIError.apiError(status: httpResponse.statusCode, message: body)
        }
        
        return data
    }
}

enum CanvasAPIError: LocalizedError {
    case invalidResponse
    case apiError(status: Int, message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Canvas returned an invalid response."
        case .apiError(let status, let message):
            return "Canvas API error \(status): \(message)"
        }
    }
}

// MARK: - Response Models

private struct CourseResponse: Decodable {
    struct Enrollment: Decodable {
        let type: String?
        let computedCurrentScore: Double?
        let computedCurrentGrade: String?
        
        var isStudentEnrollment: Bool {
            guard let type else { return false }
            let normalized = type.lowercased()
            return normalized.contains("student")
        }
    }
    
    struct Teacher: Decodable {
        let displayName: String?
    }
    
    let id: Int
    let name: String
    let courseCode: String?
    let term: Term?
    let startAt: Date?
    let endAt: Date?
    let enrollments: [Enrollment]?
    let teachers: [Teacher]?
    
    struct Term: Decodable {
        let name: String?
    }
    
    var asCanvasCourse: CanvasCourse {
        let teacherName = teachers?.first?.displayName
        let grades = enrollments?.first(where: { $0.isStudentEnrollment }) ?? enrollments?.first
        
        return CanvasCourse(
            id: id,
            name: name,
            courseCode: courseCode ?? "Course",
            termName: term?.name,
            startAt: startAt,
            endAt: endAt,
            teacherName: teacherName,
            currentScore: grades?.computedCurrentScore,
            currentGrade: grades?.computedCurrentGrade
        )
    }
}

private struct PlannerItemResponse: Decodable {
    let plannableId: Int
    let plannableType: String
    let plannable: AssignmentWrapper?
    let contextType: String?
    let courseId: Int?
    let contextName: String?
    let title: String?
    let htmlUrl: URL?
    let submissionState: String?
    
    struct AssignmentWrapper: Decodable {
        let title: String?
        let dueAt: Date?
        let pointsPossible: Double?
        let htmlUrl: URL?
    }
    
    var asPlannerItem: CanvasPlannerItem? {
        let courseId = self.courseId ?? 0
        guard courseId != 0 else { return nil }
        
        let normalizedType: String
        switch plannableType.lowercased() {
        case "assignment":
            normalizedType = "assignment"
        case "quiz":
            normalizedType = "quiz"
        case "discussion_topic":
            normalizedType = "discussion"
        case "announcement":
            normalizedType = "announcement"
        default:
            normalizedType = "other"
        }
        let type = CanvasPlannerItem.ItemType(rawValue: normalizedType) ?? .other
        let url = plannable?.htmlUrl ?? htmlUrl
        
        return CanvasPlannerItem(
            id: "\(plannableType)-\(plannableId)",
            courseId: courseId,
            courseName: contextName,
            title: plannable?.title ?? title ?? "Untitled",
            type: type,
            dueAt: plannable?.dueAt,
            htmlURL: url,
            pointsPossible: plannable?.pointsPossible,
            submitted: (submissionState ?? "").lowercased() == "submitted"
        )
    }
}

private struct AssignmentResponse: Decodable {
    struct ExternalToolAttributes: Decodable {
        let url: URL?
    }
    
    let id: Int
    let name: String
    let description: String?
    let dueAt: Date?
    let pointsPossible: Double?
    let htmlUrl: URL?
    let submissionTypes: [String]?
    let attachments: [AttachmentResponse]?
    let externalToolTagAttributes: ExternalToolAttributes?
    let updatedAt: Date?
    
    struct AttachmentResponse: Decodable {
        let id: Int
        let displayName: String?
        let contentType: String?
        let url: URL?
    }
    
    func asCanvasAssignment(courseId: Int) -> CanvasAssignment {
        CanvasAssignment(
            id: id,
            courseId: courseId,
            name: name,
            descriptionHTML: description,
            dueAt: dueAt,
            pointsPossible: pointsPossible,
            htmlURL: htmlUrl,
            submissionTypes: submissionTypes ?? [],
            attachments: (attachments ?? []).map {
                CanvasAssignmentAttachment(
                    id: $0.id,
                    displayName: $0.displayName,
                    contentType: $0.contentType,
                    url: $0.url
                )
            },
            externalToolUrl: externalToolTagAttributes?.url,
            updatedAt: updatedAt
        )
    }
}

