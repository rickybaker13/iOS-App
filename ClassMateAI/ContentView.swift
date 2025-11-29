import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddSubject = false
    @State private var showingInfo = false
    @State private var showingSettings = false
    @State private var showingCanvasDashboard = false
    @State private var showingManageCourses = false
    @State private var selectedTab = 0
    @StateObject private var canvasSyncManager = CanvasSyncManager()
    @State private var selectedCanvasCourse: CanvasCourse?
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showingOnboarding = false
    
    // Get recent lectures from all subjects
    private var recentLectures: [Lecture] {
        dataManager.subjects.flatMap { $0.lectures }
            .sorted { $0.date > $1.date }
            .prefix(3)
            .map { $0 }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                List {
                    Section(header: Text("My Subjects").appHeadlineStyle()) {
                        ForEach(dataManager.subjects) { subject in
                            NavigationLink(destination: SubjectView(subject: subject, selectedTab: $selectedTab)) {
                                SubjectRow(subject: subject)
                            }
                        }
                        
                        Button(action: {
                            showingAddSubject = true
                        }) {
                            Label("Add Subject", systemImage: "plus.circle.fill")
                                .foregroundColor(.matePrimary)
                        }
                    }
                    
                    Section(header: Text("Recent Lectures").appHeadlineStyle()) {
                        if recentLectures.isEmpty {
                            Text("No lectures yet. Start recording to see them here!")
                                .foregroundColor(.mateSecondary)
                                .italic()
                                .padding(.vertical, 8)
                        } else {
                            ForEach(recentLectures) { lecture in
                                NavigationLink(destination: LectureView(lectureId: lecture.id)) {
                                    LectureRow(lecture: lecture)
                                }
                            }
                        }
                    }
                    
                    Section(header: canvasSectionHeader) {
                        CanvasSummaryContent(
                            courses: visibleCanvasCourses,
                            showingDashboard: $showingCanvasDashboard,
                            syncAction: triggerCanvasSync,
                            isSyncing: canvasSyncManager.isSyncing,
                            onSelectCourse: { course in
                                selectedCanvasCourse = course
                            },
                            onManageCourses: { showingManageCourses = true }
                        )
                    }
                }
                .navigationTitle("StudyHack.ai")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 16) {
                            Button(action: {
                                showingInfo = true
                            }) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.matePrimary)
                                    .font(.system(size: 20))
                            }
                            
                            Button(action: {
                                showingSettings = true
                            }) {
                                Image(systemName: "gear")
                                    .foregroundColor(.matePrimary)
                                    .font(.system(size: 20))
                            }
                        }
                    }
                }
                .sheet(isPresented: $showingAddSubject) {
                    AddSubjectView()
                        .environmentObject(dataManager)
                }
                .sheet(isPresented: $showingInfo) {
                    InfoView()
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                        .environmentObject(dataManager)
                }
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            RecordingView()
                .environmentObject(dataManager)
                .tabItem {
                    Label("Record", systemImage: "mic.fill")
                }
                .tag(1)
        }
        .accentColor(.matePrimary)
        .onReceive(dataManager.objectWillChange) {
            // This ensures the view updates when DataManager changes
        }
        .sheet(isPresented: $showingCanvasDashboard) {
            NavigationView {
                CanvasDashboardView(
                    courses: visibleCanvasCourses,
                    syncManager: canvasSyncManager,
                    refreshAction: triggerCanvasSync,
                    onCourseSelected: { course in
                        selectedCanvasCourse = course
                        showingCanvasDashboard = false
                    }
                )
                .environmentObject(dataManager)
            }
        }
        .sheet(isPresented: $showingManageCourses) {
            NavigationView {
                CanvasCourseManageView()
                    .environmentObject(dataManager)
            }
        }
        .sheet(item: $selectedCanvasCourse) { course in
            NavigationView {
                CanvasCourseDetailView(course: course, syncManager: canvasSyncManager)
                    .environmentObject(dataManager)
            }
        }
        .alert(
            "Canvas Sync Failed",
            isPresented: Binding(
                get: { canvasSyncManager.lastError != nil },
                set: { if !$0 { canvasSyncManager.lastError = nil } }
            )
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(canvasSyncManager.lastError ?? "")
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            InteractiveOnboardingView()
                .environmentObject(dataManager)
        }
        .onAppear {
            if !hasCompletedOnboarding {
                showingOnboarding = true
            }
        }
    }
    
    private var canvasSectionHeader: some View {
        HStack {
            Text("Canvas Planner")
                .appHeadlineStyle()
            Spacer()
            if let lastSync = dataManager.canvasLastSync {
                Text("Last sync \(relativeDateString(from: lastSync))")
                    .font(.caption)
                    .foregroundColor(.mateSecondary)
            }
        }
    }
    
    private func triggerCanvasSync() {
        Task {
            await canvasSyncManager.sync(dataManager: dataManager)
        }
    }
    
    private func relativeDateString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private var visibleCanvasCourses: [CanvasCourse] {
        dataManager.canvasCourses.filter { !dataManager.isCourseHidden($0.id) }
    }
}

private struct CanvasSummaryContent: View {
    @EnvironmentObject private var dataManager: DataManager
    let courses: [CanvasCourse]
    @Binding var showingDashboard: Bool
    let syncAction: () -> Void
    let isSyncing: Bool
    let onSelectCourse: (CanvasCourse) -> Void
    let onManageCourses: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if courses.isEmpty && filteredPlannerItems.isEmpty {
                Text("Connect to your Canvas account to see grades, assignments, and upcoming quizzes.")
                    .font(.subheadline)
                    .foregroundColor(.mateSecondary)
                
                Button(action: syncAction) {
                    HStack {
                        if isSyncing {
                            ProgressView()
                        }
                        Text(isSyncing ? "Syncing…" : "Sync from Canvas")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.matePrimary)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            } else {
                if !courses.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(courses) { course in
                                Button(action: { onSelectCourse(course) }) {
                                    Text(course.name)
                                        .font(.headline)
                                        .foregroundColor(.matePrimary)
                                        .padding()
                                        .frame(width: 180, alignment: .leading)
                                        .background(Color.matePrimary.opacity(0.12))
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                if !filteredPlannerItems.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Upcoming")
                            .font(.headline)
                        ForEach(filteredPlannerItems.prefix(3)) { item in
                            HStack {
                                Image(systemName: item.type.iconName)
                                    .foregroundColor(.matePrimary)
                                Text(item.title)
                                    .font(.subheadline)
                                Spacer()
                                if let due = item.dueAt {
                                    Text(due, style: .date)
                                        .font(.caption)
                                        .foregroundColor(item.isOverdue ? .red : .mateSecondary)
                                }
                            }
                        }
                    }
                }
                
                HStack(spacing: 12) {
                    Button(action: {
                        showingDashboard = true
                    }) {
                        HStack {
                            Text("Open Dashboard")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color.mateBackground)
                        .cornerRadius(10)
                    }
                    
                    Button(action: onManageCourses) {
                        Label("Manage", systemImage: "slider.horizontal.3")
                            .labelStyle(.iconOnly)
                            .padding()
                            .background(Color.mateBackground)
                            .cornerRadius(10)
                    }
                    .accessibilityLabel("Manage Courses")
                }
                
                Toggle("Reminders for Canvas deadlines", isOn: Binding(
                    get: { dataManager.canvasRemindersEnabled },
                    set: { newValue in
                        dataManager.setCanvasRemindersEnabled(newValue)
                        if newValue {
                            syncAction()
                        }
                    }
                ))
            }
        }
        .padding(.vertical, 4)
    }
    
    private var filteredPlannerItems: [CanvasPlannerItem] {
        dataManager.canvasPlannerItems.filter { item in
            !dataManager.isCourseHidden(item.courseId)
        }
    }
}

struct InfoView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .center, spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 60))
                            .foregroundColor(.matePrimary)
                        
                        Text("StudyHack.ai")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.mateText)
                        
                        Text("Your AI-powered study companion")
                            .font(.title3)
                            .foregroundColor(.mateSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(
                            icon: "mic.fill",
                            title: "Record Lectures",
                            description: "Capture your lectures with high-quality audio recording"
                        )
                        
                        FeatureRow(
                            icon: "doc.text.fill",
                            title: "Auto Transcription",
                            description: "Convert speech to text with AI-powered transcription"
                        )
                        
                        FeatureRow(
                            icon: "brain",
                            title: "AI Assistant",
                            description: "Ask questions and get intelligent answers about your lectures"
                        )
                        
                        FeatureRow(
                            icon: "list.bullet",
                            title: "Smart Outlines",
                            description: "Generate structured outlines from your lecture content"
                        )
                        
                        FeatureRow(
                            icon: "exclamationmark.triangle.fill",
                            title: "Important Info",
                            description: "Automatically detect homework, tests, and important dates"
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Version")
                            .font(.headline)
                            .foregroundColor(.mateText)
                        
                        Text("1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.mateSecondary)
                    }
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
            )
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.matePrimary)
                .frame(width: 40, height: 40)
                .background(Color.mateBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.mateText)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.mateSecondary)
                    .lineLimit(nil)
            }
            
            Spacer()
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    @State private var showingExportOptions = false
    @State private var showingClearDataAlert = false
    @State private var showingOnboarding = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Data Management")) {
                    Button(action: {
                        showingExportOptions = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.matePrimary)
                            Text("Export Data")
                            Spacer()
                            Image(systemName: "chevron.right")
                            .foregroundColor(.mateSecondary)
                        }
                    }
                    
                    Button(action: {
                        showingClearDataAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Clear All Data")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
                
                Section(header: Text("Help")) {
                    Button(action: {
                        showingOnboarding = true
                    }) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.matePrimary)
                            Text("View Tutorial")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.mateSecondary)
                        }
                    }
                }
                
                Section(header: Text("App Information")) {
                    HStack {
                        Text("Total Subjects")
                        Spacer()
                        Text("\(dataManager.subjects.count)")
                            .foregroundColor(.mateSecondary)
                    }
                    
                    HStack {
                        Text("Total Lectures")
                        Spacer()
                        Text("\(dataManager.subjects.flatMap { $0.lectures }.count)")
                            .foregroundColor(.mateSecondary)
                    }
                    
                    HStack {
                        Text("Storage Used")
                Spacer()
                        Text("Calculating...")
                            .foregroundColor(.mateSecondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
            )
            .alert("Clear All Data", isPresented: $showingClearDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    dataManager.clearAllData()
                }
            } message: {
                Text("This will permanently delete all subjects, lectures, and data. This action cannot be undone.")
            }
            .fullScreenCover(isPresented: $showingOnboarding) {
                InteractiveOnboardingView()
                    .environmentObject(dataManager)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager())
}
