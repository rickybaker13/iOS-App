import SwiftUI

struct CanvasCourseManageView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            if dataManager.canvasCourses.isEmpty {
                Text("No Canvas courses available. Sync to load courses.")
                    .foregroundColor(.mateSecondary)
                    .padding(.vertical, 12)
            } else {
                ForEach(dataManager.canvasCourses) { course in
                    Toggle(isOn: visibilityBinding(for: course)) {
                        Text(course.name)
                            .foregroundColor(.mateText)
                    }
                }
            }
        }
        .navigationTitle("Manage Courses")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
    
    private func visibilityBinding(for course: CanvasCourse) -> Binding<Bool> {
        Binding(
            get: { !dataManager.isCourseHidden(course.id) },
            set: { isVisible in
                dataManager.setCourseHidden(course.id, hidden: !isVisible)
            }
        )
    }
}

