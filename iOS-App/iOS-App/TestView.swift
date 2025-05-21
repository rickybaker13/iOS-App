//
//  TestView.swift
//  iOS-App
//
//  Created by user942277 on 5/3/25.
//

import SwiftUI
import os.log

struct TestView: View {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.yourapp", category: "TestView")
    
    var body: some View {
        Text("Hello World")
            .onAppear {
                logger.info("TestView body appeared")
            }
    }
}

#Preview {
    TestView()
} 