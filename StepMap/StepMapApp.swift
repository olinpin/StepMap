//
//  StepMapApp.swift
//  StepMap
//
//  Created by Oliver Hnát on 23.11.2024.
//

import SwiftUI

@main
struct StepMapApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
