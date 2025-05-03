//
//  NewSubjectView.swift
//  iOS-App
//
//  Created by user942277 on 5/3/25.
//


import SwiftUI

struct NewSubjectView: View {
    @ObservedObject var viewModel: RecordingViewModel
    @Environment(\.dismiss) var dismiss
    @State private var subjectName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Subject Details")) {
                    TextField("Subject Name", text: $subjectName)
                }
            }
            .navigationTitle("New Subject")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    let newSubject = Subject(name: subjectName)
                    viewModel.subjects.append(newSubject)
                    dismiss()
                }
                .disabled(subjectName.isEmpty)
            )
        }
    }
}
