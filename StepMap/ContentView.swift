//
//  ContentView.swift
//  StepMap
//
//  Created by Oliver Hnát on 23.11.2024.
//

import CoreLocation
import HealthKitUI
import MapKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = ViewModel()
    @StateObject var locationManager = LocationManager()
    @StateObject var healthKitManager = HealthKitManager()

    @State private var position = MapCameraPosition.automatic
    @State private var showSearch: Bool = true
    @State private var directions: [MKRoute] = []
    @State var healthKitAccess = false
    @State var stepLength: Double?

    // TODO: create a map
    // Add navigation to the map
    // after you click the navigation button, show the start and end place on the map with a tag or whatever it's called
    // FIX: calling the directions too many times, wait till user is finished typing
    // add "cancel" button that will hide the route
    // add ability to hold on the map to place a mark (end goal)
    // Display the calculated distance and how long will it take by walking
    // Get walkingStepLength from HealthKit
    // Show how many steps does the route take
    // Get walkingSpeed
    // show how long does the route take with said walking speed

    var body: some View {
        Map(position: $position) {
            ForEach(0..<directions.count) { i in
                MapPolyline(directions[i].polyline)
                    .stroke(Constants.routeColor[i], lineWidth: Constants.routeWidth)
            }
        }
        .sheet(
            isPresented: $showSearch,
            content: {
                SearchView(
                    directions: $directions, stepLength: $stepLength,
                    locationManager: locationManager
                )
                .ignoresSafeArea()
            }
        )
        .mapControls {
            // TODO: make sure the user location stays on the map even if camera moves
            MapUserLocationButton()
                .onTapGesture {
                    locationManager.requestAuthorization()
                    locationManager.requestLocation()
                    if let userLocation = locationManager.location {
                        position = .camera(
                            MapCamera(centerCoordinate: userLocation, distance: 1000))
                    }
                }
        }
        .onAppear {
            locationManager.requestAuthorization()
            locationManager.requestLocation()
            if let userLocation = locationManager.location {
                position = .camera(MapCamera(centerCoordinate: userLocation, distance: 1000))
            }
            Task {
                await healthKitManager.requestAccess()
                stepLength = await healthKitManager.getStepLength()
            }
        }
    }

    func save(value: String) {
        viewModel.saveValue(value)
    }
}
enum Constants {
    static let routeColor: [Color] = [
        .blue,
        .red,
        .yellow,
    ]
    static let routeWidth: CGFloat = 8
}
#Preview {
    ContentView()
}
