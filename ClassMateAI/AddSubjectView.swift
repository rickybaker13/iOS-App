import SwiftUI

struct AddSubjectView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var subjects: [Subject]
    
    @State private var subjectName = ""
    @State private var selectedIcon = "book.fill"
    
    let availableIcons = [
        "book.fill", "laptopcomputer", "function", "atom", "flask.fill",
        "doc.text.fill", "chart.bar.fill", "pencil.and.ruler.fill",
        "globe.americas.fill", "person.2.fill", "brain.head.profile",
        "leaf.fill", "building.columns.fill", "music.note"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Subject Details")) {
                    TextField("Subject Name", text: $subjectName)
                    
                    VStack(alignment: .leading) {
                        Text("Choose an Icon")
                            .font(.headline)
                            .foregroundColor(.mateText)
                            .padding(.bottom, 8)
                        
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 60))
                        ], spacing: 20) {
                            ForEach(availableIcons, id: \.self) { icon in
                                Button(action: {
                                    selectedIcon = icon
                                }) {
                                    Image(systemName: icon)
                                        .font(.system(size: 24))
                                        .foregroundColor(selectedIcon == icon ? .white : .matePrimary)
                                        .frame(width: 50, height: 50)
                                        .background(selectedIcon == icon ? Color.matePrimary : Color.mateBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Add Subject")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Add") {
                    addSubject()
                }
                .disabled(subjectName.isEmpty)
            )
        }
    }
    
    private func addSubject() {
        let newSubject = Subject(
            name: subjectName,
            icon: selectedIcon,
            lectures: []
        )
        subjects.append(newSubject)
        dismiss()
    }
} 