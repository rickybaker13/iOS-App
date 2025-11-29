import SwiftUI

struct InteractiveOnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var demoData = DemoDataManager()
    @State private var currentStep = 0
    @State private var showGuide = false
    @State private var highlightedArea: HighlightArea? = nil
    
    let steps: [OnboardingStep] = [
        OnboardingStep(
            title: "Welcome to StudyHack",
            message: "Your ultimate study companion. Let's take a quick tour of your new workspace.",
            highlightArea: .none,
            accentColor: .matePrimary
        ),
        OnboardingStep(
            title: "Your Subjects",
            message: "Organize all your classes here. Tap + to add new subjects. Keep lectures, notes, and resources in one place.",
            highlightArea: .subjectsList,
            accentColor: .purple
        ),
        OnboardingStep(
            title: "Recent Activity",
            message: "Jump back into your latest lectures instantly. See what you've recorded or reviewed recently.",
            highlightArea: .recentLectures,
            accentColor: .blue
        ),
        OnboardingStep(
            title: "Canvas Sync",
            message: "Link your Canvas account to see assignments, grades, and due dates automatically synchronized.",
            highlightArea: .canvasSection,
            accentColor: .orange
        ),
        OnboardingStep(
            title: "Record Lectures",
            message: "One tap to start recording. We'll transcribe everything and create searchable notes with timestamps.",
            highlightArea: .recordTab,
            accentColor: .red
        ),
        OnboardingStep(
            title: "Smart Lectures",
            message: "Let's see what a captured lecture looks like inside...",
            highlightArea: .none,
            accentColor: .matePrimary,
            action: .showLectureDemo
        ),
        OnboardingStep(
            title: "Capture Everything",
            message: "Snap photos of whiteboards, upload PDFs, or record audio. All your materials live together.",
            highlightArea: .lectureActions,
            accentColor: .green
        ),
        OnboardingStep(
            title: "AI Notes",
            message: "Your audio becomes organized notes instantly. Edit, format, highlight, and study smarter.",
            highlightArea: .notesSection,
            accentColor: .blue
        ),
        OnboardingStep(
            title: "Ask AI",
            message: "Stuck? Ask questions about your lecture. The AI uses your specific notes and docs to answer.",
            highlightArea: .askAI,
            accentColor: .purple
        ),
        OnboardingStep(
            title: "Ready to Start?",
            message: "You're all set. Time to ace your classes with StudyHack.ai.",
            highlightArea: .none,
            accentColor: .matePrimary
        )
    ]
    
    var body: some View {
        ZStack {
            // Demo app interface in background
            if currentStep < 6 {
                DemoHomeView(demoData: demoData, highlightedArea: highlightedArea)
                    .disabled(true)
                    .blur(radius: highlightedArea == .none ? 0 : 1) // Subtle blur when focusing
            } else {
                DemoLectureView(demoData: demoData, highlightedArea: highlightedArea)
                    .disabled(true)
                    .blur(radius: highlightedArea == .none ? 0 : 1)
            }
            
            // Dark overlay with cutout for highlighted area
            if let area = highlightedArea {
                HighlightOverlay(area: area)
            }
            
            // Guide Card
            VStack {
                Spacer()
                
                if showGuide {
                    OnboardingGuideCard(
                        step: steps[currentStep],
                        currentStep: currentStep,
                        totalSteps: steps.count,
                        onNext: nextStep,
                        onSkip: completeOnboarding
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showGuide)
        }
        .onAppear {
            // Animate entrance
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showGuide = true
            }
        }
    }
    
    private func nextStep() {
        if currentStep < steps.count - 1 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showGuide = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentStep += 1
                highlightedArea = steps[currentStep].highlightArea
                
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showGuide = true
                }
            }
        } else {
            completeOnboarding()
        }
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
        dismiss()
    }
}

// MARK: - Onboarding Step Model
struct OnboardingStep {
    let title: String
    let message: String
    let highlightArea: HighlightArea
    let accentColor: Color
    var action: OnboardingAction = .none
}

enum OnboardingAction {
    case none
    case showLectureDemo
}

enum HighlightArea: Equatable {
    case none
    case subjectsList
    case recentLectures
    case canvasSection
    case recordTab
    case lectureActions
    case notesSection
    case askAI
}

// MARK: - Modern Guide Card
struct OnboardingGuideCard: View {
    let step: OnboardingStep
    let currentStep: Int
    let totalSteps: Int
    let onNext: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(step.title)
                        .font(.onboardingTitle)
                        .foregroundStyle(step.accentColor)
                    
                    Rectangle()
                        .fill(step.accentColor.opacity(0.3))
                        .frame(width: 40, height: 4)
                        .cornerRadius(2)
                }
                
                Spacer()
                
                // Progress Indicator
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(currentStep + 1) / CGFloat(totalSteps))
                        .stroke(step.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(currentStep + 1)")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }
            }
            
            // Content
            Text(step.message)
                .font(.onboardingBody)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
            
            // Controls
            HStack {
                if currentStep < totalSteps - 1 {
                    Button(action: onSkip) {
                        Text("Skip")
                            .font(.onboardingCaption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    }
                }
                
                Spacer()
                
                Button(action: onNext) {
                    HStack(spacing: 8) {
                        Text(currentStep == totalSteps - 1 ? "Get Started" : "Next")
                            .font(.appButton)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(step.accentColor)
                            .shadow(color: step.accentColor.opacity(0.4), radius: 10, y: 5)
                    )
                }
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.mateCardBackground)
                .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 40)
    }
}

// MARK: - Highlight Overlay
struct HighlightOverlay: View {
    let area: HighlightArea
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark overlay
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                
                // Cutout for highlighted area
                if area != .none {
                    Rectangle()
                        .fill(.clear)
                        .frame(width: highlightFrame(in: geometry).width,
                               height: highlightFrame(in: geometry).height)
                        .position(highlightFrame(in: geometry).origin)
                        .blendMode(.destinationOut)
                    
                    // Modern border around highlight
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.5), lineWidth: 2)
                        .frame(width: highlightFrame(in: geometry).width,
                               height: highlightFrame(in: geometry).height)
                        .position(highlightFrame(in: geometry).origin)
                        .shadow(color: .white.opacity(0.2), radius: 10)
                }
            }
        }
        .compositingGroup()
        .allowsHitTesting(false)
    }
    
    private func highlightFrame(in geometry: GeometryProxy) -> (origin: CGPoint, width: CGFloat, height: CGFloat) {
        let width = geometry.size.width
        let height = geometry.size.height
        
        switch area {
        case .none:
            return (CGPoint(x: 0, y: 0), 0, 0)
        case .subjectsList:
            return (CGPoint(x: width/2, y: height * 0.25), width - 32, height * 0.2)
        case .recentLectures:
            return (CGPoint(x: width/2, y: height * 0.48), width - 32, height * 0.18)
        case .canvasSection:
            return (CGPoint(x: width/2, y: height * 0.68), width - 32, height * 0.2)
        case .recordTab:
            return (CGPoint(x: width/2, y: height - 45), width * 0.4, 70)
        case .lectureActions:
            return (CGPoint(x: width/2, y: height * 0.32), width - 32, height * 0.25)
        case .notesSection:
            return (CGPoint(x: width/2, y: height * 0.55), width - 32, height * 0.3)
        case .askAI:
            return (CGPoint(x: width/2, y: height * 0.35), width - 80, 90)
        }
    }
}

// MARK: - Demo Data Manager
class DemoDataManager: ObservableObject {
    @Published var demoSubjects: [DemoSubject] = [
        DemoSubject(name: "Psychology 101", color: .purple, lectureCount: 12),
        DemoSubject(name: "Calculus II", color: .blue, lectureCount: 8),
        DemoSubject(name: "World History", color: .orange, lectureCount: 15)
    ]
    
    @Published var demoLectures: [DemoLecture] = [
        DemoLecture(title: "Intro to Psychology", subject: "Psychology 101", date: "2 hours ago", hasNotes: true, hasAudio: true),
        DemoLecture(title: "Derivatives Review", subject: "Calculus II", date: "Yesterday", hasNotes: true, hasAudio: true),
        DemoLecture(title: "WWI Causes", subject: "World History", date: "3 days ago", hasNotes: true, hasAudio: false)
    ]
    
    @Published var demoAssignments: [DemoAssignment] = [
        DemoAssignment(title: "Chapter 3 Quiz", course: "Psychology 101", dueDate: "Tomorrow", isUrgent: true),
        DemoAssignment(title: "Problem Set 5", course: "Calculus II", dueDate: "Friday", isUrgent: false),
        DemoAssignment(title: "Essay Draft", course: "World History", dueDate: "Next Week", isUrgent: false)
    ]
}

struct DemoSubject: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    let lectureCount: Int
}

struct DemoLecture: Identifiable {
    let id = UUID()
    let title: String
    let subject: String
    let date: String
    let hasNotes: Bool
    let hasAudio: Bool
}

struct DemoAssignment: Identifiable {
    let id = UUID()
    let title: String
    let course: String
    let dueDate: String
    let isUrgent: Bool
}

// MARK: - Demo Home View
struct DemoHomeView: View {
    @ObservedObject var demoData: DemoDataManager
    let highlightedArea: HighlightArea?
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("My Subjects").font(.appHeadline)) {
                    ForEach(demoData.demoSubjects) { subject in
                        HStack {
                            Circle()
                                .fill(subject.color)
                                .frame(width: 12, height: 12)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(subject.name)
                                    .font(.appBodyMedium)
                                Text("\(subject.lectureCount) lectures")
                                    .font(.appCaption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .opacity(highlightedArea == .subjectsList ? 1 : 0.3)
                
                Section(header: Text("Recent Lectures").font(.appHeadline)) {
                    ForEach(demoData.demoLectures) { lecture in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(lecture.title)
                                    .font(.appBodyMedium)
                                HStack(spacing: 8) {
                                    Text(lecture.subject)
                                        .font(.appCaption)
                                        .foregroundColor(.secondary)
                                    Text("•")
                                        .foregroundColor(.secondary)
                                    Text(lecture.date)
                                        .font(.appCaption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                if lecture.hasAudio {
                                    Image(systemName: "waveform")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                }
                                if lecture.hasNotes {
                                    Image(systemName: "doc.text.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .opacity(highlightedArea == .recentLectures ? 1 : 0.3)
                
                Section(header: Text("Canvas Planner").font(.appHeadline)) {
                    ForEach(demoData.demoAssignments) { assignment in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(assignment.title)
                                    .font(.appBodyMedium)
                                Text(assignment.course)
                                    .font(.appCaption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(assignment.dueDate)
                                .font(.appCaption)
                                .foregroundColor(assignment.isUrgent ? .red : .secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(assignment.isUrgent ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
                                )
                        }
                        .padding(.vertical, 8)
                    }
                }
                .opacity(highlightedArea == .canvasSection ? 1 : 0.3)
            }
            .navigationTitle("StudyHack")
        }
    }
}

// MARK: - Demo Lecture View
struct DemoLectureView: View {
    @ObservedObject var demoData: DemoDataManager
    let highlightedArea: HighlightArea?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Actions section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Actions")
                            .font(.appHeadline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ActionCard(icon: "camera.fill", title: "Capture", color: .green)
                                ActionCard(icon: "doc.badge.plus", title: "Upload", color: .blue)
                                ActionCard(icon: "mic.fill", title: "Record", color: .red)
                                ActionCard(icon: "sparkles", title: "Ask AI", color: .purple)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .opacity(highlightedArea == .lectureActions || highlightedArea == .askAI ? 1 : 0.3)
                    
                    // Notes section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notes")
                            .font(.appHeadline)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Introduction to Psychology")
                                .font(.appTitle)
                            
                            Text("Today we covered the basics of cognitive psychology and how memory works. We discussed short-term vs long-term memory...")
                                .font(.appBody)
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                            
                            HStack {
                                Image(systemName: "clock")
                                    .font(.caption)
                                Text("0:45")
                                    .font(.caption)
                                Text("Key concepts discussed")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .foregroundColor(.blue)
                            .padding(.top, 8)
                        }
                        .padding()
                        .background(Color.mateCardBackground)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
                        .padding(.horizontal)
                    }
                    .opacity(highlightedArea == .notesSection ? 1 : 0.3)
                }
                .padding(.vertical)
            }
            .navigationTitle("Intro to Psychology")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.mateBackground)
        }
    }
}

struct ActionCard: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            Text(title)
                .font(.appCaption)
                .fontWeight(.medium)
        }
        .frame(width: 80, height: 80)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
        )
    }
}

// Preview
struct InteractiveOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        InteractiveOnboardingView()
            .environmentObject(DataManager())
    }
}
