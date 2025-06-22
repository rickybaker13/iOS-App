import SwiftUI

struct SubjectView: View {
    let subject: Subject
    @EnvironmentObject var dataManager: DataManager
    @State private var showingNewLecture = false
    
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: subject.icon)
                        .font(.system(size: 40))
                        .foregroundColor(.matePrimary)
                        .frame(width: 60, height: 60)
                        .background(Color.mateBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    VStack(alignment: .leading) {
                        Text(subject.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.mateText)
                        Text("\(subject.lectures.count) Lectures")
                            .font(.subheadline)
                            .foregroundColor(.mateSecondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("Lectures")) {
                ForEach(subject.lectures) { lecture in
                    NavigationLink(destination: LectureView(lecture: lecture)) {
                        LectureRow(lecture: lecture)
                    }
                }
            }
        }
        .navigationTitle(subject.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingNewLecture = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(.matePrimary)
                }
            }
        }
        .sheet(isPresented: $showingNewLecture) {
            NewLectureView(subject: subject)
        }
    }
}

struct LectureDetailView: View {
    let lecture: Lecture
    @State private var isPlaying = false
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    // Recording Player
                    HStack {
                        Button(action: { isPlaying.toggle() }) {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.matePrimary)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(lecture.title)
                                .font(.headline)
                            Text(lecture.date, style: .date)
                                .font(.subheadline)
                                .foregroundColor(.mateSecondary)
                        }
                    }
                    .padding()
                    .background(Color.mateBackground)
                    .cornerRadius(12)
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                            .foregroundColor(.mateText)
                        Text(lecture.notes)
                            .font(.body)
                            .foregroundColor(.mateText)
                    }
                    .padding()
                    .background(Color.mateBackground)
                    .cornerRadius(12)
                    
                    // Outline
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Outline")
                            .font(.headline)
                            .foregroundColor(.mateText)
                        Text(lecture.outline)
                            .font(.body)
                            .foregroundColor(.mateText)
                    }
                    .padding()
                    .background(Color.mateBackground)
                    .cornerRadius(12)
                }
            }
        }
        .navigationTitle("Lecture Details")
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