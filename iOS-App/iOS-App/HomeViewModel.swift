//
//  HomeViewModel.swift
//  iOS-App
//
//  Created by user942277 on 5/3/25.
//

import Foundation

class HomeViewModel: ObservableObject {
    @Published var userName: String = "Alex"
    @Published var recentLectures: [Lecture] = []
    @Published var upcomingAssignments: [Assignment] = []
    
    init() {
        // Load user data and recent items
        loadUserData()
    }
    
    private func loadUserData() {
        // TODO: Implement data loading
    }
}
