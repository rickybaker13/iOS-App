import SwiftUI

struct AIQuestionView: View {
    let lecture: Lecture
    @StateObject private var aiService = AIService()
    @State private var question = ""
    @State private var answer = ""
    @State private var showingError = false
    @Environment(\.dismiss) private var dismiss
    
    init(lecture: Lecture) {
        self.lecture = lecture
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Question Input
                VStack(alignment: .leading) {
                    Text("Your Question")
                        .font(.headline)
                    TextEditor(text: $question)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                // Submit Button
                Button(action: submitQuestion) {
                    HStack {
                        if aiService.isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "questionmark.circle.fill")
                        }
                        Text("Submit Question")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(question.isEmpty || aiService.isProcessing)
                
                // Answer Display
                if !answer.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Answer")
                            .font(.headline)
                        Text(answer)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        if aiService.tokenCount > 0 {
                            Text("Tokens used: \(aiService.tokenCount)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Ask AI")
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(aiService.error ?? "An unknown error occurred")
        }
    }
    
    private func submitQuestion() {
        // Combine notes and outline for context
        let context = [lecture.notes, lecture.outline]
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
        
        Task {
            do {
                let response = try await aiService.askQuestion(about: context, question: question)
                await MainActor.run {
                    answer = response
                }
            } catch {
                await MainActor.run {
                    aiService.error = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
} 