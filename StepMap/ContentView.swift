//
//  ContentView.swift
//  StepMap
//
//  Created by Oliver Hnát on 23.11.2024.
//

import SwiftUI
import CoreData

struct ContentView: View {
    
    // TODO: create a map
    // Add navigation to the map
    // Display the calculated distance and how long will it take by walking
    // Get walkingStepLength from HealthKit
    // Show how many steps does the route take
    // Get walkingSpeed
    // show how long does the route take with said walking speed

    var body: some View {
        NavigationView {
            List {
                Text("HER")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("Edit")
                }
            }
            Text("Select an item")
        }
    }
}
#Preview {
    ContentView()
}
