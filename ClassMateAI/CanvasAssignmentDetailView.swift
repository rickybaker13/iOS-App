import SwiftUI
import UniformTypeIdentifiers
import UserNotifications

struct CanvasAssignmentDetailView: View {
    let course: CanvasCourse
    let assignment: CanvasAssignment
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var notes: String = ""
    @State private var showingDocumentPicker = false
    @State private var previewItem: ResourcePreviewItem?
    @State private var showingReminderAlert = false
    @State private var reminderMessage = ""
    @State private var showingDatePicker = false
    @State private var selectedDate = Date()
    
    private var state: AssignmentState? {
        dataManager.assignmentState(for: course.id, assignmentId: assignment.id)
    }
    
    private var assignmentResources: [CourseResource] {
        dataManager.resources(forAssignment: assignment.id)
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(assignment.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let dueAt = assignment.dueAt {
                        HStack {
                            Image(systemName: "calendar")
                            Text("Due: \(dateFormatter.string(from: dueAt))")
                        }
                        .font(.subheadline)
                        .foregroundColor(dueAt < Date() ? .red : .mateSecondary)
                    }
                    
                    if let points = assignment.pointsPossible {
                        Text("Points: \(String(format: "%.0f", points))")
                            .font(.caption)
                            .foregroundColor(.mateSecondary)
                    }
                }
                .padding(.vertical, 8)
                
                if !assignment.descriptionText.isEmpty {
                    Text(assignment.descriptionText)
                        .font(.body)
                        .foregroundColor(.mateText)
                }
                
                if let url = assignment.htmlURL {
                    Link("Open in Canvas", destination: url)
                        .font(.subheadline)
                        .foregroundColor(.matePrimary)
                }
            }
            
            Section(header: Text("Notes")) {
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
                    .onChange(of: notes) { newValue in
                        dataManager.updateAssignmentNotes(courseId: course.id, assignmentId: assignment.id, notes: newValue)
                    }
            }
            
            Section(header: Text("My Resources")) {
                if assignmentResources.isEmpty {
                    Text("No documents uploaded")
                        .font(.caption)
                        .foregroundColor(.mateSecondary)
                } else {
                    ForEach(assignmentResources) { resource in
                        Button {
                            handleResourceTap(resource)
                        } label: {
                            HStack {
                                Image(systemName: iconName(for: resource.type))
                                    .foregroundColor(.matePrimary)
                                Text(resource.title)
                                Spacer()
                                if resource.hasLocalFile {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                dataManager.deleteCourseResource(resource)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                
                Button {
                    showingDocumentPicker = true
                } label: {
                    Label("Upload Document", systemImage: "doc.badge.plus")
                }
            }
            
            Section {
                Menu {
                    if let dueAt = assignment.dueAt {
                        Section("Relative to Due Date") {
                            Button("1 hour before") {
                                scheduleReminder(at: dueAt.addingTimeInterval(-3600))
                            }
                            Button("24 hours before") {
                                scheduleReminder(at: dueAt.addingTimeInterval(-86400))
                            }
                        }
                    }
                    
                    Section("Remind Me Later") {
                        Button("In 1 Hour") {
                            scheduleReminder(at: Date().addingTimeInterval(3600))
                        }
                        Button("Tomorrow Morning (9 AM)") {
                            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                            let nineAM = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow)!
                            scheduleReminder(at: nineAM)
                        }
                        Button("Custom Date...") {
                            selectedDate = Date().addingTimeInterval(3600)
                            showingDatePicker = true
                        }
                    }
                } label: {
                    HStack {
                        Text("Set Reminder")
                        Spacer()
                        Image(systemName: "bell")
                    }
                }
                
                Button {
                    dataManager.toggleAssignmentCompletion(courseId: course.id, assignmentId: assignment.id)
                } label: {
                    HStack {
                        Text(state?.isCompleted == true ? "Mark as Incomplete" : "Mark as Complete")
                        Spacer()
                        if state?.isCompleted == true {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        }
                    }
                }
                .tint(state?.isCompleted == true ? .orange : .green)
                
                Button {
                    dataManager.toggleAssignmentSavedForLater(courseId: course.id, assignmentId: assignment.id)
                } label: {
                    HStack {
                        Text(state?.savedForLater == true ? "Remove from Later" : "Save for Later")
                        Spacer()
                        if state?.savedForLater == true {
                            Image(systemName: "bookmark.fill").foregroundColor(.blue)
                        }
                    }
                }
                .tint(state?.savedForLater == true ? .blue : .gray)
                
                if state?.isRemoved == true {
                     Button {
                        dataManager.restoreAssignment(courseId: course.id, assignmentId: assignment.id)
                        dismiss()
                    } label: {
                        Text("Restore Assignment").foregroundColor(.blue)
                    }
                } else {
                    Button(role: .destructive) {
                        dataManager.removeAssignment(courseId: course.id, assignmentId: assignment.id)
                        dismiss()
                    } label: {
                        Text("Delete Assignment")
                    }
                }
            }
        }
        .navigationTitle("Assignment Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            notes = state?.notes ?? ""
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPickerView(supportedTypes: [UTType.pdf, UTType.text, UTType.image, UTType.plainText]) { url in
                importDocument(from: url)
            }
        }
        .sheet(item: $previewItem) { item in
            ResourcePreviewController(item: item)
        }
        .alert("Reminder", isPresented: $showingReminderAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(reminderMessage)
        }
        .sheet(isPresented: $showingDatePicker) {
            NavigationView {
                VStack(spacing: 20) {
                    DatePicker(
                        "Select Date & Time",
                        selection: $selectedDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .padding()
                    
                    Text("Reminder will be sent on:")
                        .font(.caption)
                        .foregroundColor(.mateSecondary)
                    
                    Text(dateFormatter.string(from: selectedDate))
                        .font(.headline)
                        .foregroundColor(.matePrimary)
                }
                .navigationTitle("Schedule Reminder")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingDatePicker = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Schedule") {
                            scheduleReminder(at: selectedDate)
                            showingDatePicker = false
                        }
                    }
                }
            }
            .presentationDetents([.large])
        }
    }
    
    private func scheduleReminder(at date: Date) {
        guard date > Date() else {
            reminderMessage = "Cannot schedule reminder in the past."
            showingReminderAlert = true
            return
        }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    let content = UNMutableNotificationContent()
                    content.title = "Assignment Due Soon"
                    content.body = "\(assignment.name) is due in \(course.name)"
                    content.sound = .default
                    
                    let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                    let request = UNNotificationRequest(identifier: "assignment-\(assignment.id)", content: content, trigger: trigger)
                    
                    UNUserNotificationCenter.current().add(request) { error in
                        DispatchQueue.main.async {
                            if let error = error {
                                reminderMessage = "Failed to schedule: \(error.localizedDescription)"
                            } else {
                                let formatter = DateFormatter()
                                formatter.dateStyle = .short
                                formatter.timeStyle = .short
                                reminderMessage = "Reminder set for \(formatter.string(from: date))"
                            }
                            showingReminderAlert = true
                        }
                    }
                } else {
                    reminderMessage = "Notifications are disabled. Please enable them in Settings."
                    showingReminderAlert = true
                }
            }
        }
    }
    
    private func importDocument(from url: URL) {
        Task {
            do {
                let startAccess = url.startAccessingSecurityScopedResource()
                defer { if startAccess { url.stopAccessingSecurityScopedResource() } }
                
                let fileName = url.lastPathComponent
                let data = try Data(contentsOf: url)
                
                // Save to app storage
                let savedURL = try ResourceStorageService.shared.saveResourceData(data, fileName: fileName, courseId: course.id)
                
                let resource = CourseResource(
                    courseId: course.id,
                    assignmentId: assignment.id,
                    title: fileName,
                    fileName: fileName,
                    type: CourseResource.ResourceType.from(contentType: nil, fileExtension: url.pathExtension),
                    source: .manualUpload,
                    sizeInBytes: Int64(data.count)
                )
                
                await MainActor.run {
                    dataManager.addCourseResource(resource)
                }
            } catch {
                print("Error importing document: \(error)")
            }
        }
    }
    
    private func handleResourceTap(_ resource: CourseResource) {
        if let localURL = ResourceStorageService.shared.localFileURL(for: resource) {
            previewItem = ResourcePreviewItem(url: localURL, title: resource.title)
        }
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

