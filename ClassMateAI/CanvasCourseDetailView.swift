import SwiftUI

struct CanvasCourseDetailView: View {
    let course: CanvasCourse
    @ObservedObject var syncManager: CanvasSyncManager
    
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @State private var isRefreshing = false
    @StateObject private var resourceImporter = ResourceImportService()
    @State private var previewItem: ResourcePreviewItem?
    
    private var allAssignments: [CanvasAssignment] {
        dataManager.getCanvasAssignments(for: course.id)
            .sorted { (lhs, rhs) in
                switch (lhs.dueAt, rhs.dueAt) {
                case let (l?, r?):
                    return l < r
                case (nil, _?):
                    return false
                case (_?, nil):
                    return true
                default:
                    return lhs.name < rhs.name
                }
            }
    }
    
    private func state(for assignment: CanvasAssignment) -> AssignmentState? {
        dataManager.assignmentState(for: course.id, assignmentId: assignment.id)
    }
    
    private var upcomingAssignments: [CanvasAssignment] {
        allAssignments.filter { assignment in
            guard let state = state(for: assignment) else { return true }
            return !state.isRemoved && !state.savedForLater && !state.isCompleted
        }
    }
    
    private var savedForLaterAssignments: [CanvasAssignment] {
        allAssignments.filter { assignment in
            guard let state = state(for: assignment) else { return false }
            return state.savedForLater && !state.isRemoved
        }
    }
    
    private var completedAssignments: [CanvasAssignment] {
        allAssignments.filter { assignment in
            guard let state = state(for: assignment) else { return false }
            return state.isCompleted && !state.isRemoved
        }
    }
    
    var body: some View {
        List {
            Section(header: Text("Overview")) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(course.name)
                            .font(.headline)
                        if let teacher = course.teacherName {
                            Text("Teacher: \(teacher)")
                                .font(.subheadline)
                                .foregroundColor(.mateSecondary)
                        }
                        if let term = course.termName {
                            Text(term)
                                .font(.caption)
                                .foregroundColor(.mateSecondary)
                        }
                    }
                    Spacer()
                    Text(course.displayGrade)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.matePrimary)
                }
                
                Button(action: refreshAssignments) {
                    HStack {
                        if isRefreshing || syncManager.isSyncing {
                            ProgressView()
                        }
                        Text(isRefreshing ? "Refreshing…" : "Refresh Assignments")
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            
            Section(header: Text("Assignments & Upcoming Work")) {
                if upcomingAssignments.isEmpty {
                    Text("No assignments available. Pull to refresh or try again later.")
                        .foregroundColor(.mateSecondary)
                } else {
                    ForEach(upcomingAssignments) { assignment in
                        NavigationLink(destination: CanvasAssignmentDetailView(course: course, assignment: assignment)) {
                            AssignmentRow(
                                course: course,
                                assignment: assignment,
                                state: state(for: assignment)
                            )
                        }
                        .environmentObject(dataManager)
                        .swipeActions(edge: .leading) {
                            Button(role: .destructive) {
                                dataManager.removeAssignment(courseId: course.id, assignmentId: assignment.id)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                dataManager.toggleAssignmentSavedForLater(courseId: course.id, assignmentId: assignment.id)
                            } label: {
                                Label("Later", systemImage: "clock")
                            }
                            .tint(.blue)
                            
                            Button {
                                dataManager.toggleAssignmentCompletion(courseId: course.id, assignmentId: assignment.id)
                            } label: {
                                Label("Complete", systemImage: "checkmark")
                            }
                            .tint(.green)
                        }
                    }
                }
            }
            
            if !savedForLaterAssignments.isEmpty {
                Section(header: Text("Saved for Later")) {
                    ForEach(savedForLaterAssignments) { assignment in
                        NavigationLink(destination: CanvasAssignmentDetailView(course: course, assignment: assignment)) {
                            AssignmentRow(
                                course: course,
                                assignment: assignment,
                                state: state(for: assignment)
                            )
                        }
                        .environmentObject(dataManager)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                dataManager.toggleAssignmentSavedForLater(courseId: course.id, assignmentId: assignment.id)
                            } label: {
                                Label("Move to Upcoming", systemImage: "arrow.uturn.backward")
                            }
                            .tint(.blue)
                            
                            Button {
                                dataManager.toggleAssignmentCompletion(courseId: course.id, assignmentId: assignment.id)
                            } label: {
                                Label("Complete", systemImage: "checkmark")
                            }
                            .tint(.green)
                        }
                        .swipeActions(edge: .leading) {
                            Button(role: .destructive) {
                                dataManager.removeAssignment(courseId: course.id, assignmentId: assignment.id)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            
            if !completedAssignments.isEmpty {
                Section(header: Text("Completed")) {
                    ForEach(completedAssignments) { assignment in
                        NavigationLink(destination: CanvasAssignmentDetailView(course: course, assignment: assignment)) {
                            AssignmentRow(
                                course: course,
                                assignment: assignment,
                                state: state(for: assignment)
                            )
                        }
                        .environmentObject(dataManager)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                dataManager.toggleAssignmentCompletion(courseId: course.id, assignmentId: assignment.id)
                            } label: {
                                Label("Mark Incomplete", systemImage: "arrow.uturn.backward")
                            }
                            .tint(.orange)
                        }
                        .swipeActions(edge: .leading) {
                            Button(role: .destructive) {
                                dataManager.removeAssignment(courseId: course.id, assignmentId: assignment.id)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            
            let savedResources = dataManager.resources(for: course.id)
            if !savedResources.isEmpty {
                Section(header: Text("Saved Resources")) {
                    ForEach(savedResources) { resource in
                        Button {
                            handleResourceTap(resource)
                        } label: {
                            CourseResourceRow(resource: resource)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                dataManager.deleteCourseResource(resource)
                            } label: {
                                Label("Delete Resource", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(course.courseCode)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") { dismiss() }
            }
        }
        .sheet(item: $previewItem) { item in
            ResourcePreviewController(item: item)
        }
        .task {
            if allAssignments.isEmpty {
                await refreshAssignments()
            }
        }
    }
    
    private func refreshAssignments() {
        Task {
            isRefreshing = true
            await syncManager.syncAssignments(for: course, dataManager: dataManager)
            isRefreshing = false
        }
    }
}

private struct AssignmentRow: View {
    let course: CanvasCourse
    let assignment: CanvasAssignment
    let state: AssignmentState?
    @EnvironmentObject private var dataManager: DataManager
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(assignment.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                if state?.isCompleted == true {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else if state?.savedForLater == true {
                    Image(systemName: "bookmark.fill")
                        .foregroundColor(.blue)
                }
            }
            
            HStack {
                if let dueAt = assignment.dueAt {
                    Text("Due \(dateFormatter.string(from: dueAt))")
                        .font(.caption)
                        .foregroundColor(dueAt < Date() && state?.isCompleted != true ? .red : .mateSecondary)
                }
                
                if let points = assignment.pointsPossible {
                    Text("• \(String(format: "%.0f pts", points))")
                        .font(.caption)
                        .foregroundColor(.mateSecondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Resource Preview
// AttachmentRow removed as it is now in CanvasAssignmentDetailView


private struct CourseResourceRow: View {
    let resource: CourseResource
    
    var body: some View {
        HStack {
            Image(systemName: iconName(for: resource.type))
                .foregroundColor(.matePrimary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(resource.title)
                    .font(.headline)
                Text(resourceSubtitle)
                    .font(.caption)
                    .foregroundColor(.mateSecondary)
            }
            Spacer()
            if resource.hasLocalFile {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .accessibilityLabel("Downloaded")
            }
        }
        .padding(.vertical, 4)
    }
    
    private var resourceSubtitle: String {
        var parts: [String] = []
        parts.append(resource.type.displayName)
        parts.append("Imported \(relativeDate(from: resource.importedAt))")
        if let sizeString = sizeDescription {
            parts.append(sizeString)
        }
        return parts.joined(separator: " • ")
    }
    
    private var sizeDescription: String? {
        guard let size = resource.sizeInBytes else { return nil }
        return CourseResource.displayFormatter(for: size)
    }
    
    private func relativeDate(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func iconName(for type: CourseResource.ResourceType) -> String {
        switch type {
        case .pdf: return "doc.richtext"
        case .slideDeck: return "play.rectangle"
        case .document: return "doc.text"
        case .spreadsheet: return "tablecells"
        case .image: return "photo"
        case .audio: return "waveform"
        case .link: return "link"
        case .other: return "doc"
        }
    }
}

// MARK: - Resource Preview

private extension CanvasCourseDetailView {
    func handleResourceTap(_ resource: CourseResource) {
        if let localURL = ResourceStorageService.shared.localFileURL(for: resource) {
            previewItem = ResourcePreviewItem(url: localURL, title: resource.title)
        } else if let remoteURL = resource.remoteURL {
            UIApplication.shared.open(remoteURL)
        }
    }
}

