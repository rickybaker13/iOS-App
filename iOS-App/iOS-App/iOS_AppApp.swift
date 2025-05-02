//
//  iOS_AppApp.swift
//  iOS-App
//
//  Created by user942277 on 5/2/25.
//

import SwiftUI

@main
struct iOS_AppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
