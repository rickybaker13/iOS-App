//
//  iOS_AppApp.swift
//  iOS-App
//
//  Created by user942277 on 5/2/25.
//

import SwiftUI
import os.log

@main
struct iOS_AppApp: App {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.yourapp", category: "App")
    
    init() {
        logger.info("App initialization started")
        do {
            // Add any initialization code here
            logger.info("App initialization completed successfully")
        } catch {
            logger.error("App initialization failed: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            TestView()
                .onAppear {
                    logger.info("TestView appeared")
                }
                .onDisappear {
                    logger.info("TestView disappeared")
                }
        }
    }
}
