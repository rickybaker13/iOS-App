//
//  HomeViewModel.swift
//  iOS-App
//
//  Created by user942277 on 5/3/25.
//

import Foundation
import SwiftUI

// Import the module containing our models
import iOS_App

// Make sure Models.swift is in the same target
class HomeViewModel: ObservableObject {
    @Published var userName: String = "Alex"
    @Published var recentLectures: [AppModels.Lecture] = []
    @Published var upcomingAssignments: [AppModels.Assignment] = []
    
    init() {
        // Load user data and recent items
        loadUserData()
    }
    
    private func loadUserData() {
        // TODO: Implement data loading
    }
}
