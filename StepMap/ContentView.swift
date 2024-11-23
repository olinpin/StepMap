//
//  ContentView.swift
//  StepMap
//
//  Created by Oliver Hnát on 23.11.2024.
//

import SwiftUI
import MapKit

struct ContentView: View {
    
    @ObservedObject var viewModel = ViewModel()
    
    @State private var position = MapCameraPosition.automatic
    @State private var showSearch: Bool = true
    // TODO: create a map
    // Add navigation to the map
    // Display the calculated distance and how long will it take by walking
    // Get walkingStepLength from HealthKit
    // Show how many steps does the route take
    // Get walkingSpeed
    // show how long does the route take with said walking speed

    var body: some View {
        Map(position: $position)
//            .ignoresSafeArea()
            .sheet(isPresented: $showSearch, content: {
                SearchView()
            })
//        Text("This is what's set: \(viewModel.test)")
//        Button(action: {
//            save(value: "te5t3")
//        }, label: {Text("CLICK ME")})
    }
    
    func save(value: String) {
        viewModel.saveValue(value)
    }
}
#Preview {
    ContentView()
}
