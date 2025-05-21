//
//  ContentView.swift
//  iOS-App
//
//  Created by user942277 on 5/2/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        TabView {
            RecordingView()
                .tabItem {
                    Label("Record", systemImage: "mic")
                }
            
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
