import Foundation
import UIKit

class AIService: ObservableObject {
    @Published var isProcessing = false
    @Published var error: String?
    @Published var tokenCount: Int = 0
    
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let visionModel = "gpt-4o-mini"
    
    init() {
        self.apiKey = Config.openAIApiKey
    }
    
    func askQuestion(about content: String, question: String) async throws -> String {
        isProcessing = true
        defer { isProcessing = false }
        
        // Check if content is sufficient
        guard content.count > 50 else {
            throw AIError.insufficientContent("The lecture content is too short to provide a meaningful answer. Please ensure you have transcribed notes or an outline.")
        }
        
        let truncatedContent = truncateContent(content, maxLength: 3000)
        
        let prompt = """
        You are an expert educational AI assistant helping a student understand their lecture content. 
        
        LECTURE CONTENT:
        \(truncatedContent)
        
        STUDENT'S QUESTION:
        \(question)
        
        INSTRUCTIONS:
        - Provide a clear, concise, and educational response
        - Use simple language that a student can understand
        - If the question cannot be answered from the lecture content, clearly state this
        - Include relevant examples or analogies when helpful
        - Structure your response with clear paragraphs
        - If applicable, suggest follow-up questions the student might want to ask
        
        RESPONSE:
        """
        
        return try await makeAPIRequest(prompt: prompt, systemMessage: "You are a helpful educational AI assistant.")
    }
    
    func generateQuestions(from content: String, count: Int = 5) async throws -> [String] {
        isProcessing = true
        defer { isProcessing = false }
        
        // Check if content is sufficient
        guard content.count > 100 else {
            throw AIError.insufficientContent("The lecture content is too short to generate meaningful questions. Please ensure you have transcribed notes or an outline with sufficient detail.")
        }
        
        let truncatedContent = truncateContent(content, maxLength: 3000)
        
        let prompt = """
        Based on the following lecture content, generate \(count) thoughtful questions that would help a student test their understanding and deepen their knowledge.
        
        LECTURE CONTENT:
        \(truncatedContent)
        
        INSTRUCTIONS:
        - Generate a mix of different question types (comprehension, application, analysis)
        - Questions should be clear and specific
        - Avoid yes/no questions
        - Focus on key concepts and important details
        - Make questions that encourage critical thinking
        
        FORMAT:
        Return only the questions, one per line, numbered 1-\(count).
        Do not include any other text or explanations.
        """
        
        let response = try await makeAPIRequest(prompt: prompt, systemMessage: "You are an expert educator creating assessment questions.")
        
        // Parse the response into individual questions
        let lines = response.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var questions: [String] = []
        for line in lines {
            // Remove numbering if present
            let question = line.replacingOccurrences(of: "^\\d+\\.\\s*", with: "", options: .regularExpression)
            if !question.isEmpty {
                questions.append(question)
            }
        }
        
        return Array(questions.prefix(count))
    }
    
    func generateSummary(from content: String) async throws -> String {
        isProcessing = true
        defer { isProcessing = false }
        
        // Check if content is sufficient
        guard content.count > 50 else {
            throw AIError.insufficientContent("The lecture content is too short to generate a meaningful summary. Please ensure you have transcribed notes or an outline.")
        }
        
        let truncatedContent = truncateContent(content, maxLength: 4000)
        
        let prompt = """
        Create a comprehensive summary of the following lecture content.
        
        LECTURE CONTENT:
        \(truncatedContent)
        
        INSTRUCTIONS:
        - Create a well-structured summary that captures the main points
        - Use clear, concise language
        - Organize information logically
        - Include key concepts, definitions, and important details
        - Maintain the educational value of the content
        - Keep the summary comprehensive but not overly long
        
        SUMMARY:
        """
        
        return try await makeAPIRequest(prompt: prompt, systemMessage: "You are an expert at creating educational summaries.")
    }
    
    func explainConcept(concept: String, in context: String) async throws -> String {
        isProcessing = true
        defer { isProcessing = false }
        
        // Check if content is sufficient
        guard context.count > 30 else {
            throw AIError.insufficientContent("The lecture content is too short to provide context for the concept. Please ensure you have transcribed notes or an outline.")
        }
        
        let truncatedContext = truncateContent(context, maxLength: 3000)
        
        let prompt = """
        Explain the concept "\(concept)" in the context of the following lecture content.
        
        LECTURE CONTENT:
        \(truncatedContext)
        
        INSTRUCTIONS:
        - Provide a clear, detailed explanation of the concept
        - Relate it to the broader context of the lecture
        - Use examples or analogies to make it easier to understand
        - Explain why this concept is important
        - If the concept is not mentioned in the lecture, provide a general explanation
        
        EXPLANATION:
        """
        
        return try await makeAPIRequest(prompt: prompt, systemMessage: "You are an expert educator explaining complex concepts.")
    }
    
    func generateStructuredNotes(from transcription: String) async throws -> String {
        isProcessing = true
        defer { isProcessing = false }
        
        // Check if content is sufficient
        guard transcription.count > 50 else {
            throw AIError.insufficientContent("The transcription is too short to generate meaningful notes. Please ensure you have a clear recording.")
        }
        
        let truncatedTranscription = truncateContent(transcription, maxLength: 4000)
        
        let prompt = """
        You are an expert educational note-taker. Create well-structured lecture notes from the transcription below while preserving the important supporting details, explanations, and context. The goal is to give the student comprehensive study notes—NOT a terse summary.
        
        TRANSCRIPTION:
        \(truncatedTranscription)
        
        INSTRUCTIONS:
        - Preserve all meaningful facts, steps, examples, and definitions; do not over-compress the content
        - Remove filler words, repeated phrases, and speech artifacts while keeping the original intent
        - Combine fragments into complete sentences so each bullet is self-contained and easy to study
        - Keep the language clear and academic, and include clarifying details (causes/effects, cautions, stats, procedures) when provided
        - Organize information into logical sections and ensure each section stays on-topic
        - Provide at least three bullets per section when the lecture supports it, and include more when necessary
        - Make examples concrete and explicitly connect them to the concept they illustrate
        
        FORMAT:
        Return the notes using the EXACT markers below so the app can parse each section. Do not include any additional sections or text outside this template.
        
        [[SECTION:Key Points]]
        • Bullet sentences describing essential themes or procedures
        • ...
        
        [[SECTION:Important Definitions]]
        • Term — clear definition with critical qualifiers
        • ...
        
        [[SECTION:Examples]]
        • Specific example tied to the relevant concept, including the outcome or implication
        • ...
        
        [[SECTION:Summary]]
        • Key takeaways tying the lecture together or highlighting next steps
        • ...
        
        RULES:
        - Keep every bullet on its own line.
        - If a section legitimately lacks content, write "• No new information discussed."
        - If the transcript seems meta (instructions, prompts, or partial thoughts), reinterpret whatever text is available and still create structured notes about that material.
        - Never apologize, refuse, or ask for more input. If context is missing, mention the limitation inside the Summary section as a bullet (e.g., "• Additional details were not captured in the recording.").
        - Do not output anything before the first [[SECTION:...]] or after the Summary section.
        
        NOTES:
        """
        
        return try await makeAPIRequest(prompt: prompt, systemMessage: "You are an expert note-taker who produces detailed, well-organized study notes that retain important supporting context.")
    }
    
    func generateStructuredNotesWithSections(from transcription: String, timestamps: [NotesTimestamp]) async throws -> (String, [NotesTimestamp]) {
        isProcessing = true
        defer { isProcessing = false }
        
        // Check if content is sufficient
        guard transcription.count > 50 else {
            throw AIError.insufficientContent("The transcription is too short to generate meaningful notes. Please ensure you have a clear recording.")
        }
        
        let truncatedTranscription = truncateContent(transcription, maxLength: 4000)
        
        // Create a mapping of content to timestamps for the AI
        let timestampInfo = timestamps.map { "\($0.sectionTitle): \($0.timestamp)s" }.joined(separator: "\n")
        
        let prompt = """
        Create comprehensive, well-structured lecture notes from the following transcription. The transcription may contain incomplete sentences, filler words, and speech patterns that need to be cleaned up and organized into coherent notes.
        
        TRANSCRIPTION:
        \(truncatedTranscription)
        
        TIMESTAMP SEGMENTS:
        \(timestampInfo)
        
        INSTRUCTIONS:
        - Clean up the transcription by removing filler words, incomplete sentences, and speech artifacts
        - Organize the content into logical sections with clear headings
        - Create coherent, complete sentences that capture the key points
        - Identify and highlight important concepts, definitions, and key terms
        - Structure the notes in a way that would be useful for studying
        - Use bullet points and numbered lists where appropriate
        - Maintain the educational value and accuracy of the content
        - If there are examples or case studies mentioned, include them clearly
        - Add any relevant connections or relationships between concepts
        - IMPORTANT: Create 3-5 main sections that correspond to the timestamp segments provided
        - Each section should have a clear, descriptive heading
        
        FORMAT:
        Create the notes with this structure:
        
        LECTURE NOTES
        ==================================================
        
        [Section 1 Title]
        [Content for section 1]
        
        [Section 2 Title]
        [Content for section 2]
        
        [Section 3 Title]
        [Content for section 3]
        
        [Continue with additional sections as needed]
        
        NOTES:
        """
        
        let notes = try await makeAPIRequest(prompt: prompt, systemMessage: "You are an expert note-taker and educator who creates clear, organized, and useful lecture notes.")
        
        // Parse the notes to extract sections and create timestamps
        let sectionTimestamps = parseNotesSections(notes: notes, timestamps: timestamps)
        
        return (notes, sectionTimestamps)
    }
    
    private func parseNotesSections(notes: String, timestamps: [NotesTimestamp]) -> [NotesTimestamp] {
        var sectionTimestamps: [NotesTimestamp] = []
        let lines = notes.components(separatedBy: .newlines)
        var currentSectionTitle: String?
        var currentSectionStart = 0
        
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check if this line looks like a section heading
            if isSectionHeading(trimmedLine) {
                // Save previous section if exists
                if let title = currentSectionTitle {
                    let sectionEnd = notes.count
                    if let timestamp = findBestTimestamp(for: title, in: timestamps) {
                        let sectionTimestamp = NotesTimestamp(
                            sectionTitle: title,
                            timestamp: timestamp.timestamp,
                            startIndex: currentSectionStart,
                            endIndex: sectionEnd
                        )
                        sectionTimestamps.append(sectionTimestamp)
                    }
                }
                
                // Start new section
                currentSectionTitle = trimmedLine
                currentSectionStart = notes.count
            }
        }
        
        // Handle the last section
        if let title = currentSectionTitle {
            let sectionEnd = notes.count
            if let timestamp = findBestTimestamp(for: title, in: timestamps) {
                let sectionTimestamp = NotesTimestamp(
                    sectionTitle: title,
                    timestamp: timestamp.timestamp,
                    startIndex: currentSectionStart,
                    endIndex: sectionEnd
                )
                sectionTimestamps.append(sectionTimestamp)
            }
        }
        
        return sectionTimestamps
    }
    
    private func isSectionHeading(_ line: String) -> Bool {
        // Check if line looks like a section heading
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count > 3 && 
               trimmed.count < 100 && 
               !trimmed.hasPrefix("•") && 
               !trimmed.hasPrefix("-") && 
               !trimmed.hasPrefix("*") &&
               !trimmed.contains(":") && // Avoid lines with colons (like "Key Concepts:")
               trimmed.uppercased() == trimmed || // All caps
               trimmed.first?.isUppercase == true // Starts with capital
    }
    
    private func findBestTimestamp(for sectionTitle: String, in timestamps: [NotesTimestamp]) -> NotesTimestamp? {
        // Try to find a timestamp that matches the section title
        let lowercasedTitle = sectionTitle.lowercased()
        
        // First, try exact match
        if let exactMatch = timestamps.first(where: { $0.sectionTitle.lowercased() == lowercasedTitle }) {
            return exactMatch
        }
        
        // Then try partial match
        if let partialMatch = timestamps.first(where: { lowercasedTitle.contains($0.sectionTitle.lowercased()) || $0.sectionTitle.lowercased().contains(lowercasedTitle) }) {
            return partialMatch
        }
        
        // Finally, return the first available timestamp
        return timestamps.first
    }
    
    func generateStructuredOutline(from transcription: String) async throws -> String {
        isProcessing = true
        defer { isProcessing = false }
        
        // Check if content is sufficient
        guard transcription.count > 50 else {
            throw AIError.insufficientContent("The transcription is too short to generate meaningful outline. Please ensure you have a clear recording.")
        }
        
        let truncatedTranscription = truncateContent(transcription, maxLength: 4000)
        
        let prompt = """
        Create a well-structured, hierarchical outline from the following lecture transcription. The transcription may contain incomplete sentences, filler words, and speech patterns that need to be cleaned up and organized into a logical outline structure.
        
        TRANSCRIPTION:
        \(truncatedTranscription)
        
        INSTRUCTIONS:
        - Clean up the transcription by removing filler words, incomplete sentences, and speech artifacts
        - Identify the main topics and subtopics discussed in the lecture
        - Create a hierarchical outline with clear main points, subpoints, and details
        - Use proper outline formatting with numbers, letters, and indentation
        - Ensure the outline flows logically and captures the lecture structure
        - Include key concepts, definitions, and important points
        - If there are examples or case studies, include them as subpoints
        - Make the outline useful for studying and review
        
        FORMAT:
        Create the outline with this structure:
        
        OUTLINE
        ==================================================
        
        I. [Main Topic 1]
           A. [Subtopic 1.1]
              1. [Detail 1.1.1]
              2. [Detail 1.1.2]
           B. [Subtopic 1.2]
              1. [Detail 1.2.1]
              2. [Detail 1.2.2]
        
        II. [Main Topic 2]
            A. [Subtopic 2.1]
              1. [Detail 2.1.1]
              2. [Detail 2.1.2]
            B. [Subtopic 2.2]
              1. [Detail 2.2.1]
              2. [Detail 2.2.2]
        
        III. [Main Topic 3]
             A. [Subtopic 3.1]
             B. [Subtopic 3.2]
        
        OUTLINE:
        """
        
        return try await makeAPIRequest(prompt: prompt, systemMessage: "You are an expert educator who creates clear, logical, and well-structured outlines for educational content.")
    }
    
    private func truncateContent(_ content: String, maxLength: Int) -> String {
        if content.count <= maxLength {
            return content
        }
        
        // For longer content, try to get a representative sample
        // Take from beginning, middle, and end to get better coverage
        let words = content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        if words.count <= 200 {
            // If content is short enough, just truncate at sentence boundary
            let truncated = String(content.prefix(maxLength))
            if let lastSentenceEnd = truncated.lastIndex(of: ".") {
                return String(truncated[..<lastSentenceEnd]) + "."
            }
            return truncated + "..."
        } else {
            // For longer content, create a comprehensive summary by taking samples from different parts
            let wordCount = words.count
            let sampleSize = min(100, wordCount / 4) // Take about 100 words from each section
            
            let beginning = words.prefix(sampleSize).joined(separator: " ")
            let quarter1 = wordCount / 4
            let quarter2 = wordCount / 2
            let quarter3 = (wordCount * 3) / 4
            
            let middle1 = words.dropFirst(quarter1).prefix(sampleSize).joined(separator: " ")
            let middle2 = words.dropFirst(quarter2).prefix(sampleSize).joined(separator: " ")
            let end = words.suffix(sampleSize).joined(separator: " ")
            
            let combined = "BEGINNING: \(beginning)... MIDDLE 1: \(middle1)... MIDDLE 2: \(middle2)... END: \(end)"
            
            if combined.count <= maxLength {
                return combined
            } else {
                // If still too long, take a more aggressive approach
                let aggressiveSampleSize = min(50, wordCount / 6)
                let beginning = words.prefix(aggressiveSampleSize).joined(separator: " ")
                let middle = words.dropFirst(wordCount / 2).prefix(aggressiveSampleSize).joined(separator: " ")
                let end = words.suffix(aggressiveSampleSize).joined(separator: " ")
                
                let shortCombined = "BEGINNING: \(beginning)... MIDDLE: \(middle)... END: \(end)"
                return String(shortCombined.prefix(maxLength)) + "..."
            }
        }
    }
    
    private func makeAPIRequest(prompt: String, systemMessage: String) async throws -> String {
        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": systemMessage],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 2000,
            "top_p": 1.0,
            "frequency_penalty": 0.0,
            "presence_penalty": 0.0
        ]
        
        guard let url = URL(string: baseURL) else {
            throw AIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60.0
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw AIError.processingError
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIError.invalidResponse
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                    throw AIError.apiError(errorResponse.error.message)
                }
                throw AIError.invalidResponse
            }
            
            let result = try JSONDecoder().decode(AIResponse.self, from: data)
            
            // Update token count
            if let usage = result.usage {
                await MainActor.run {
                    self.tokenCount = usage.total_tokens
                }
            }
            
            return result.choices.first?.message.content ?? "No response generated"
        } catch {
            if let aiError = error as? AIError {
                throw aiError
            }
            throw AIError.processingError
        }
    }
    
    func validateAPIKey() async -> Bool {
        do {
            let testPrompt = "Hello, this is a test message."
            _ = try await makeAPIRequest(prompt: testPrompt, systemMessage: "You are a helpful assistant.")
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Visual Analysis with GPT-4V
    
    func analyzeImageWithVision(image: UIImage, question: String, lectureContext: String? = nil) async throws -> String {
        isProcessing = true
        defer { isProcessing = false }
        
        // Convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw AIError.processingError
        }
        
        let base64Image = imageData.base64EncodedString()
        
        // Create context-aware prompt
        var prompt = """
        You are an expert educational AI assistant helping a student understand visual content from their lecture.
        
        STUDENT'S QUESTION:
        \(question)
        """
        
        if let context = lectureContext, !context.isEmpty {
            prompt += """
            
            LECTURE CONTEXT:
            \(context)
            """
        }
        
        prompt += """
        
        INSTRUCTIONS:
        - Analyze the image carefully and provide a clear, educational response
        - If the image contains mathematical equations, explain the concepts and provide step-by-step solutions
        - If the image shows diagrams or charts, explain what they represent
        - If the image contains text or slides, summarize the key points
        - Use simple, student-friendly language
        - Provide examples or analogies when helpful
        - If the image appears blurry or low resolution, describe any visible structure, shapes, colors, or partial text rather than saying you cannot see it
        - Only state that the image cannot be seen if the data is completely blank or corrupted
        
        RESPONSE:
        """
        
        return try await makeVisionAPIRequest(image: base64Image, prompt: prompt)
    }
    
    private func makeVisionAPIRequest(image: String, prompt: String) async throws -> String {
        let requestBody: [String: Any] = [
            "model": visionModel,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": prompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(image)",
                                "detail": "high"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 1000,
            "temperature": 0.7
        ]
        
        guard let url = URL(string: baseURL) else {
            throw AIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120.0 // Longer timeout for vision requests
        
        do {
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw AIError.processingError
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIError.invalidResponse
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                    throw AIError.apiError(errorResponse.error.message)
                }
                throw AIError.invalidResponse
            }
            
            let result = try JSONDecoder().decode(AIResponse.self, from: data)
            
            // Update token count
            if let usage = result.usage {
                await MainActor.run {
                    self.tokenCount = usage.total_tokens
                }
            }
            
            return result.choices.first?.message.content ?? "No response generated"
        } catch {
            if let aiError = error as? AIError {
                throw aiError
            }
            throw AIError.processingError
        }
    }
}

// MARK: - Supporting Types

struct AIResponse: Codable {
    let choices: [Choice]
    let usage: TokenUsage?
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String
    }
    
    struct TokenUsage: Codable {
        let total_tokens: Int
    }
}

struct APIErrorResponse: Codable {
    let error: APIError
    
    struct APIError: Codable {
        let message: String
    }
}

enum AIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case processingError
    case apiError(String)
    case invalidAPIKey
    case insufficientContent(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .processingError:
            return "Error processing the request"
        case .apiError(let message):
            return message
        case .invalidAPIKey:
            return "Invalid API key. Please check your configuration."
        case .insufficientContent(let message):
            return message
        }
    }
} 