//
//  HomeView.swift
//  iOS-App
//
//  Created by user942277 on 5/3/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Welcome Header
                Text("Welcome, \(viewModel.userName)")
                    .font(.title)
                    .padding()
                
                // Main Actions
                VStack(spacing: 15) {
                    NavigationLink(destination: RecordingView()) {
                        ActionButton(title: "Record New Lecture", icon: "mic.fill", color: .red)
                    }
                    
                    NavigationLink(destination: RecentLecturesView()) {
                        ActionButton(title: "Recent Lectures", icon: "book.fill", color: .blue)
                    }
                    
                    NavigationLink(destination: AssignmentsView()) {
                        ActionButton(title: "Upcoming Work", icon: "calendar", color: .green)
                    }
                    
                    NavigationLink(destination: StudyMaterialsView()) {
                        ActionButton(title: "Study Materials", icon: "doc.text.fill", color: .orange)
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("StudyBuddy")
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
            Text(title)
                .font(.headline)
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .cornerRadius(10)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
