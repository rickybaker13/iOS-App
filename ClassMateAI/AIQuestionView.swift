import SwiftUI
import UIKit
import PDFKit

struct AIQuestionView: View {
    let lecture: Lecture
    @StateObject private var aiService = AIService()
    @State private var question = ""
    @State private var answer = ""
    @State private var showingError = false
    @State private var generatedQuestions: [String] = []
    @State private var showingGeneratedQuestions = false
    @State private var selectedAction: AIAction = .askQuestion
    @State private var selectedLectureImage: LectureImage?
    @State private var selectedLectureResource: LectureResource?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager
    
    enum AIAction: String, CaseIterable {
        case askQuestion = "Ask Question"
        case generateQuestions = "Generate Questions"
        case explainConcept = "Explain Concept"
        case generateSummary = "Generate Summary"
        
        var icon: String {
            switch self {
            case .askQuestion: return "questionmark.circle.fill"
            case .generateQuestions: return "list.bullet.circle.fill"
            case .explainConcept: return "lightbulb.fill"
            case .generateSummary: return "doc.text.fill"
            }
        }
    }
    
    init(lecture: Lecture) {
        self.lecture = lecture
    }

    private var lectureImages: [LectureImage] {
        dataManager.getLectureImages(for: lecture.id)
    }

    private var lectureResources: [LectureResource] {
        dataManager.lectureResources(for: lecture.id)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // AI Action Selector
                VStack(alignment: .leading, spacing: 12) {
                    Text("AI Assistant")
                        .font(.headline)
                        .foregroundColor(.mateText)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(AIAction.allCases, id: \.self) { action in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        selectedAction = action
                                        question = ""
                                        answer = ""
                                        generatedQuestions = []
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: action.icon)
                                            .font(.system(size: 16))
                                        Text(action.rawValue)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(selectedAction == action ? .white : .matePrimary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(selectedAction == action ? Color.matePrimary : Color.mateBackground)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(selectedAction == action ? Color.matePrimary : Color.mateSecondary.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                
                // Dynamic Input Section
                switch selectedAction {
                case .askQuestion:
                    questionInputSection
                    if !lectureImages.isEmpty {
                        visualAttachmentSection
                    }
                    if !lectureResources.isEmpty {
                        resourceAttachmentSection
                    }
                    if let image = selectedLectureImage, !image.questions.isEmpty {
                        visualHistorySection(for: image)
                    }
                case .explainConcept:
                    conceptInputSection
                case .generateQuestions, .generateSummary:
                    generateSection
                }
                
                // Submit Button
                Button(action: performAction) {
                    HStack(spacing: 12) {
                        if aiService.isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: selectedAction.icon)
                                .font(.system(size: 18))
                        }
                        Text(buttonTitle)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canSubmit ? Color.matePrimary : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: canSubmit ? Color.matePrimary.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
                }
                .disabled(!canSubmit || aiService.isProcessing)
                .padding(.top, 8)
                
                // Generated Questions Display
                if !generatedQuestions.isEmpty && selectedAction == .generateQuestions {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Generated Questions")
                            .font(.headline)
                            .foregroundColor(.mateText)
                        
                        ForEach(Array(generatedQuestions.enumerated()), id: \.offset) { index, question in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    self.question = question
                                    selectedAction = .askQuestion
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Text("\(index + 1).")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.mateSecondary)
                                        .frame(width: 30, alignment: .leading)
                                    
                                    Text(question)
                                        .font(.subheadline)
                                        .foregroundColor(.mateText)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(3)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundColor(.matePrimary)
                                        .font(.system(size: 20))
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(Color.mateCardBackground)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.mateSecondary.opacity(0.2), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.top, 16)
                }
                
                // Answer Display
                if !answer.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(resultTitle)
                                .font(.headline)
                                .foregroundColor(.mateText)
                            
                            Spacer()
                            
                            if aiService.tokenCount > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.mateSecondary)
                                        .font(.system(size: 14))
                                    Text("\(aiService.tokenCount) tokens")
                                        .font(.caption)
                                        .foregroundColor(.mateSecondary)
                                }
                            }
                        }
                        
                    if let image = selectedLectureImage,
                           let uiImage = loadImage(for: image) {
                            HStack(spacing: 12) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Visual referenced")
                                        .font(.subheadline)
                                        .bold()
                                    if let description = image.description, !description.isEmpty {
                                        Text(description)
                                            .font(.caption)
                                            .foregroundColor(.mateSecondary)
                                            .lineLimit(2)
                                    }
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color.mateSecondary.opacity(0.1))
                            .cornerRadius(12)
                        } else if let resource = selectedLectureResource {
                            HStack(spacing: 12) {
                                Image(systemName: resource.type.iconName)
                                    .font(.system(size: 30))
                                    .foregroundColor(.matePrimary)
                                    .frame(width: 60, height: 60)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Document referenced")
                                        .font(.subheadline)
                                        .bold()
                                    Text(resource.title)
                                        .font(.caption)
                                        .foregroundColor(.mateText)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color.mateSecondary.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        Text(answer)
                            .font(.body)
                            .foregroundColor(.mateText)
                            .padding(16)
                            .background(Color.mateBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.mateSecondary.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.top, 16)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("AI Assistant")
        .navigationBarTitleDisplayMode(.large)
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(aiService.error ?? "An unknown error occurred")
        }
    }
    
    private var questionInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Question")
                .font(.headline)
                .foregroundColor(.mateText)
            
            TextEditor(text: $question)
                .frame(minHeight: 120)
                .padding(12)
                .background(Color.mateBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.mateSecondary.opacity(0.3), lineWidth: 1)
                )
                .onChange(of: question) { _ in
                    // Clear answer when question changes
                    if !answer.isEmpty {
                        answer = ""
                    }
                }
        }
    }
    
    private var conceptInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Concept to Explain")
                .font(.headline)
                .foregroundColor(.mateText)
            
            TextField("Enter a concept or term...", text: $question)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 8)
                .onChange(of: question) { _ in
                    // Clear answer when concept changes
                    if !answer.isEmpty {
                        answer = ""
                    }
                }
        }
    }
    
    private var generateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(sectionTitle)
                .font(.headline)
                .foregroundColor(.mateText)
            
            Text(sectionDescription)
                .font(.subheadline)
                .foregroundColor(.mateSecondary)
                .lineLimit(nil)
            
            if !hasContent {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("No lecture content available. Please add notes or generate an outline first.")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }

    private var visualAttachmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Attach Lecture Visual")
                    .font(.headline)
                    .foregroundColor(.mateText)
                Spacer()
                if selectedLectureImage != nil {
                    Button("Clear") {
                        selectedLectureImage = nil
                    }
                    .font(.caption)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(lectureImages) { image in
                        VisualThumbnail(
                            image: image,
                            uiImage: loadImage(for: image),
                            isSelected: selectedLectureImage?.id == image.id
                        )
                        .onTapGesture {
                            if selectedLectureImage?.id == image.id {
                                selectedLectureImage = nil
                            } else {
                                selectedLectureImage = image
                                selectedLectureResource = nil // Mutually exclusive
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var resourceAttachmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Attach Document")
                    .font(.headline)
                    .foregroundColor(.mateText)
                Spacer()
                if selectedLectureResource != nil {
                    Button("Clear") {
                        selectedLectureResource = nil
                    }
                    .font(.caption)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(lectureResources) { resource in
                        ResourceThumbnail(
                            resource: resource,
                            isSelected: selectedLectureResource?.id == resource.id
                        )
                        .onTapGesture {
                            if selectedLectureResource?.id == resource.id {
                                selectedLectureResource = nil
                            } else {
                                selectedLectureResource = resource
                                selectedLectureImage = nil // Mutually exclusive
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func visualHistorySection(for image: LectureImage) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Previous Q&A for this visual")
                .font(.subheadline)
                .foregroundColor(.mateText)
            
            ForEach(image.questions.sorted(by: { $0.timestamp > $1.timestamp }).prefix(3)) { qa in
                VStack(alignment: .leading, spacing: 6) {
                    Text(qa.question)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(.mateText)
                    Text(qa.answer)
                        .font(.caption)
                        .foregroundColor(.mateSecondary)
                }
                .padding(10)
                .background(Color.mateSecondary.opacity(0.1))
                .cornerRadius(10)
            }
            
            if image.questions.count > 3 {
                Text("View full history in Lecture Visuals.")
                    .font(.caption)
                    .foregroundColor(.mateSecondary)
            }
        }
    }
    
    private var buttonTitle: String {
        switch selectedAction {
        case .askQuestion: return "Ask Question"
        case .generateQuestions: return "Generate Questions"
        case .explainConcept: return "Explain Concept"
        case .generateSummary: return "Generate Summary"
        }
    }
    
    private var resultTitle: String {
        switch selectedAction {
        case .askQuestion: return "Answer"
        case .generateQuestions: return "Generated Questions"
        case .explainConcept: return "Explanation"
        case .generateSummary: return "Summary"
        }
    }
    
    private var sectionTitle: String {
        switch selectedAction {
        case .generateQuestions: return "Question Generation"
        case .generateSummary: return "Summary Generation"
        default: return ""
        }
    }
    
    private var sectionDescription: String {
        switch selectedAction {
        case .generateQuestions: return "AI will generate 5 thoughtful questions based on your lecture content to help test your understanding."
        case .generateSummary: return "AI will create a comprehensive summary of your lecture content, highlighting key points and concepts."
        default: return ""
        }
    }
    
    private var canSubmit: Bool {
        switch selectedAction {
        case .askQuestion, .explainConcept:
            return !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .generateQuestions, .generateSummary:
            return hasContent
        }
    }
    
    private var hasContent: Bool {
        !lecture.notes.isEmpty || !lecture.outline.isEmpty
    }
    
    private func loadImage(for lectureImage: LectureImage) -> UIImage? {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagesPath = documents
            .appendingPathComponent("LectureImages")
            .appendingPathComponent(lectureImage.lectureId.uuidString)
            .appendingPathComponent(lectureImage.imageFileName)
        return UIImage(contentsOfFile: imagesPath.path)
    }

    @MainActor
    private func storeVisualQA(question: String, answer: String, for image: LectureImage) {
        let qa = ImageQuestion(question: question, answer: answer)
        dataManager.appendQuestion(qa, to: image.id, lectureId: lecture.id)
        let updatedImages = dataManager.getLectureImages(for: lecture.id)
        if let updated = updatedImages.first(where: { $0.id == image.id }) {
            selectedLectureImage = updated
        }
    }
    
    private func performAction() {
        var contextComponents: [String] = []
        
        // Base lecture notes/outline
        let baseContext = [lecture.notes, lecture.outline]
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
        if !baseContext.isEmpty {
            contextComponents.append("LECTURE NOTES AND OUTLINE:\n\(baseContext)")
        }
        
        // Selected Document Content
        if let resource = selectedLectureResource,
           let content = readResourceContent(resource) {
            contextComponents.append("DOCUMENT CONTENT (\(resource.title)):\n\(content)")
        }
        
        let context = contextComponents.joined(separator: "\n\n---\n\n")
        let hasContext = !context.isEmpty
        
        if selectedAction != .askQuestion && !hasContext {
            aiService.error = "No lecture content available. Please add notes or generate an outline first."
            showingError = true
            return
        }
        
        let trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        if (selectedAction == .askQuestion || selectedAction == .explainConcept),
           trimmedQuestion.isEmpty {
            aiService.error = "Please enter a question."
            showingError = true
            return
        }
        
        Task {
            do {
                switch selectedAction {
                case .askQuestion:
                    if let image = selectedLectureImage,
                       let uiImage = loadImage(for: image) {
                        // Visual Q&A
                        let response = try await aiService.analyzeImageWithVision(
                            image: uiImage,
                            question: trimmedQuestion,
                            lectureContext: hasContext ? context : nil
                        )
                        await MainActor.run {
                            answer = response
                            generatedQuestions = []
                            storeVisualQA(question: trimmedQuestion, answer: response, for: image)
                        }
                    } else {
                        // Document or Context Q&A
                        guard hasContext else {
                            await MainActor.run {
                                aiService.error = "Add lecture notes, attach a visual, or select a document before asking."
                                showingError = true
                            }
                            return
                        }
                        
                        let response = try await aiService.askQuestion(about: context, question: trimmedQuestion)
                        await MainActor.run {
                            answer = response
                            generatedQuestions = []
                        }
                    }
                    
                case .generateQuestions:
                    let questions = try await aiService.generateQuestions(from: context, count: 5)
                    await MainActor.run {
                        generatedQuestions = questions
                        answer = ""
                    }
                    
                case .explainConcept:
                    let response = try await aiService.explainConcept(concept: trimmedQuestion, in: context)
                    await MainActor.run {
                        answer = response
                        generatedQuestions = []
                    }
                    
                case .generateSummary:
                    let response = try await aiService.generateSummary(from: context)
                    await MainActor.run {
                        answer = response
                        generatedQuestions = []
                    }
                }
            } catch {
                await MainActor.run {
                    aiService.error = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    
    private func readResourceContent(_ resource: LectureResource) -> String? {
        guard let url = ResourceStorageService.shared.localFileURL(for: resource) else { return nil }
        
        // Start accessing security scoped resource if needed
        let access = url.startAccessingSecurityScopedResource()
        defer {
            if access {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        switch resource.type {
        case .pdf:
            if let pdfDocument = PDFDocument(url: url) {
                return pdfDocument.string
            }
        case .document:
            if let content = try? String(contentsOf: url, encoding: .utf8) {
                return content
            }
            // Try ASCII/other encodings if utf8 fails?
             if let content = try? String(contentsOf: url, encoding: .ascii) {
                return content
            }
        default:
            break
        }
        return nil
    }
}

private struct ResourceThumbnail: View {
    let resource: LectureResource
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.mateSecondary.opacity(0.1))
                    .frame(width: 90, height: 90)
                
                Image(systemName: resource.type.iconName)
                    .font(.system(size: 32))
                    .foregroundColor(.matePrimary)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.matePrimary : Color.clear, lineWidth: 3)
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.matePrimary)
                        .padding(6)
                }
            }
            
            Text(resource.title)
                .font(.caption)
                .foregroundColor(.mateText)
                .lineLimit(1)
                .frame(width: 90)
        }
    }
}

private struct VisualThumbnail: View {
    let image: LectureImage
    let uiImage: UIImage?
    let isSelected: Bool
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.white)
                        )
                }
            }
            .frame(width: 90, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.matePrimary : Color.clear, lineWidth: 3)
            )
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.matePrimary)
                    .padding(6)
            }
        }
    }
}