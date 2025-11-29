import Foundation

enum Config {
    // IMPORTANT: Replace with your actual API key from environment variable or secure storage
    // Never commit API keys to version control
    static let openAIApiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "YOUR_OPENAI_API_KEY_HERE"
 
    // Configuration for GPT-4-mini
    static let maxTokens = 1000  // Increased token limit for GPT-4-mini
    static let temperature = 0.5  // Slightly lower temperature for more focused responses
    
    // Canvas API configuration (development only)
    // IMPORTANT: Replace with your actual Canvas access token from environment variable or secure storage
    static let canvasBaseURL = URL(string: "https://knoxschools.instructure.com/api/v1")!
    static let canvasAccessToken = ProcessInfo.processInfo.environment["CANVAS_ACCESS_TOKEN"] ?? "YOUR_CANVAS_ACCESS_TOKEN_HERE"
}
