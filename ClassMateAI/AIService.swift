import Foundation

class AIService: ObservableObject {
    @Published var isProcessing = false
    @Published var error: String?
    @Published var tokenCount: Int = 0
    
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    init() {
        self.apiKey = Config.openAIApiKey
    }
    
    func askQuestion(about content: String, question: String) async throws -> String {
        isProcessing = true
        defer { isProcessing = false }
        
        let prompt = """
        You are a helpful AI assistant helping a student understand their lecture content.
        Here is the lecture content:
        
        \(content)
        
        Student's question: \(question)
        
        Please provide a clear, concise, and helpful response. If the question cannot be answered from the lecture content, say so.
        """
        
        let requestBody: [String: Any] = [
            "model": "gpt-4-mini",
            "messages": [
                ["role": "system", "content": "You are a helpful AI assistant helping a student understand their lecture content."],
                ["role": "user", "content": prompt]
            ],
            "temperature": Config.temperature,
            "max_tokens": Config.maxTokens
        ]
        
        guard let url = URL(string: baseURL) else {
            throw AIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
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
        }
    }
} 