import SwiftUI

struct AddSubjectView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    @State private var subjectName = ""
    @State private var selectedIcon = "book.fill"
    @State private var showingSuccess = false
    @State private var isAdding = false
    
    let availableIcons = [
        "book.fill", "laptopcomputer", "function", "atom", "flask.fill",
        "doc.text.fill", "chart.bar.fill", "pencil.and.ruler.fill",
        "globe.americas.fill", "person.2.fill", "brain.head.profile",
        "leaf.fill", "building.columns.fill", "music.note", "paintbrush.fill",
        "camera.fill", "gamecontroller.fill", "heart.fill", "star.fill",
        "graduationcap.fill", "microscope.fill", "testtube.2", "book.closed.fill",
        "text.book.closed.fill", "newspaper.fill", "doc.richtext.fill"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Subject Details")) {
                    TextField("Subject Name", text: $subjectName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.words)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose an Icon")
                            .font(.headline)
                            .foregroundColor(.mateText)
                        
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 60))
                        ], spacing: 16) {
                            ForEach(availableIcons, id: \.self) { icon in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        selectedIcon = icon
                                    }
                                }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: icon)
                                            .font(.system(size: 24))
                                            .foregroundColor(selectedIcon == icon ? .white : .matePrimary)
                                            .frame(width: 50, height: 50)
                                            .background(selectedIcon == icon ? Color.matePrimary : Color.mateElementBackground)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(selectedIcon == icon ? Color.matePrimary : Color.clear, lineWidth: 2)
                                            )
                                            .scaleEffect(selectedIcon == icon ? 1.1 : 1.0)
                                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedIcon)
                                        
                                        if selectedIcon == icon {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(.matePrimary)
                                                .background(Color.white)
                                                .clipShape(Circle())
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    Button(action: addSubject) {
                        HStack {
                            if isAdding {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "plus.circle.fill")
                            }
                            Text(isAdding ? "Adding..." : "Add Subject")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(subjectName.isEmpty ? Color.gray : Color.matePrimary)
                        .cornerRadius(10)
                    }
                    .disabled(subjectName.isEmpty || isAdding)
                }
            }
            .navigationTitle("Add Subject")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
                .disabled(isAdding)
            )
            .overlay(
                Group {
                    if showingSuccess {
                        VStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            Text("Subject Added!")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.mateText)
                        }
                        .padding()
                        .background(Color.mateCardBackground)
                        .cornerRadius(16)
                        .shadow(radius: 10)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            )
        }
    }
    
    private func addSubject() {
        guard !subjectName.isEmpty else { return }
        
        isAdding = true
        
        // Simulate a brief delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let newSubject = Subject(
                name: subjectName.trimmingCharacters(in: .whitespacesAndNewlines),
                icon: selectedIcon,
                lectures: []
            )
            
            dataManager.addSubject(newSubject)
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showingSuccess = true
            }
            
            // Dismiss after showing success
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                dismiss()
            }
        }
    }
} 