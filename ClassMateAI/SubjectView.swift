import SwiftUI

struct SubjectView: View {
    let subject: Subject
    @EnvironmentObject var dataManager: DataManager
    @State private var showingNewLecture = false
    @Binding var selectedTab: Int
    
    // Get the current subject data from DataManager
    private var currentSubject: Subject? {
        dataManager.subjects.first { $0.id == subject.id }
    }
    
    var body: some View {
        ZStack {
            Color.mateBackground.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header Card
                    headerCard
                    
                    // Lectures Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Lectures")
                            .font(.appHeadline)
                            .padding(.horizontal, 4)
                        
                        let lectures = currentSubject?.lectures ?? subject.lectures
                        if !lectures.isEmpty {
                            ForEach(lectures) { lecture in
                                // Use a wrapper to prevent navigation popping when lecture data changes
                                LectureNavigationWrapper(lecture: lecture)
                            }
                        } else {
                            emptyStateView
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(currentSubject?.name ?? subject.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingNewLecture = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.matePrimary)
                }
            }
        }
        .sheet(isPresented: $showingNewLecture) {
            NewLectureView(subject: currentSubject ?? subject)
        }
        .onAppear {
            dataManager.objectWillChange.send()
        }
    }
    
    private var headerCard: some View {
        HStack(spacing: 16) {
            Image(systemName: currentSubject?.icon ?? subject.icon)
                .font(.system(size: 32))
                .foregroundColor(.matePrimary)
                .frame(width: 60, height: 60)
                .background(Color.mateElementBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(currentSubject?.name ?? subject.name)
                    .font(.appTitle)
                    .foregroundColor(.mateText)
                
                HStack {
                    Image(systemName: "doc.text.fill")
                        .font(.caption)
                        .foregroundColor(.mateSecondary)
                    Text("\(currentSubject?.lectures.count ?? subject.lectures.count) Lectures")
                        .font(.appCaption)
                        .foregroundColor(.mateSecondary)
                }
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color.mateCardBackground)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.mateSecondary.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Lectures Yet")
                    .font(.appHeadline)
                    .foregroundColor(.mateText)
                
                Text("Start recording to add your first lecture to this subject.")
                    .font(.appBody)
                    .foregroundColor(.mateSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: {
                selectedTab = 1
            }) {
                HStack {
                    Image(systemName: "record.circle")
                    Text("Start Recording")
                }
                .font(.appButton)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(Color.matePrimary)
                .foregroundColor(.white)
                .cornerRadius(25)
                .shadow(color: Color.matePrimary.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.top, 10)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(Color.mateCardBackground)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

// Wrapper view to stabilize navigation when lecture data updates
struct LectureNavigationWrapper: View {
    let lecture: Lecture
    
    var body: some View {
        NavigationLink(destination: LectureView(lectureId: lecture.id)) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(lecture.title)
                        .font(.appBodyMedium)
                        .foregroundColor(.mateText)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text(lecture.date, style: .date)
                                .font(.appCaption)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                            Text(formatDuration(lecture.duration))
                                .font(.appCaption)
                        }
                    }
                    .foregroundColor(.mateSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.mateSecondary.opacity(0.7))
            }
            .padding(16)
            .background(Color.mateCardBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        return "\(minutes) min"
    }
}

struct NewLectureView: View {
    let subject: Subject
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Lecture Details")) {
                    TextField("Title", text: .constant(""))
                    DatePicker("Date", selection: .constant(Date()), displayedComponents: [.date])
                }
            }
            .navigationTitle("New Lecture")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Create") { dismiss() }
            )
        }
    }
}
