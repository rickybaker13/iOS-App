//
//  NewSubcategoryView.swift
//  iOS-App
//
//  Created by user942277 on 5/3/25.
//

import SwiftUI

struct NewSubcategoryView: View {
    @ObservedObject var viewModel: RecordingViewModel
    @Environment(\.dismiss) var dismiss
    @State private var subcategoryName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Subcategory Details")) {
                    TextField("Subcategory Name", text: $subcategoryName)
                }
            }
            .navigationTitle("New Subcategory")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    if let subject = viewModel.selectedSubject {
                        let newSubcategory = Subcategory(name: subcategoryName)
                        // TODO: Update the subject's subcategories
                        dismiss()
                    }
                }
                .disabled(subcategoryName.isEmpty)
            )
        }
    }
}
