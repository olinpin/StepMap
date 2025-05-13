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

    @State private var position: MapCameraPosition = .automatic
    @State private var showSearch: Bool = true
    @State private var directions: [MKRoute] = []
    @State private var destination: MKMapItem?

    
    @State var healthKitAccess = false
    @State var stepLength: Double?

    // TODO: create a map
    // Add navigation to the map
    // after you click the navigation button, show the start and end place on the map with a tag or whatever it's called
    // FIX: calling the directions too many times, wait till user is finished typing
    // add "cancel" button that will hide the route
    // add ability to hold on the map to place a mark (end goal)
    // Display the calculated distance and how long will it take by walking
    // Get walkingSpeed
    // show how long does the route take with said walking speed
    // Add favorite locations - like home, work, etc (probably should be stored in core data tho:/)
    
    // FIX: search is bad lol

    
    // How to speed up?
    // calculate only the distance between the start and end instead of getting directions for everything
    // if user clicks on the place, display better view and then calculate route there
    var body: some View {
        ZStack {
        MapView(locationManager: locationManager)
//        Map(position: $position) {
//            UserAnnotation()
//            ForEach(0..<directions.count) { i in
//                if destination != nil {
//                    Marker(item: destination!)
//                }
//                MapPolyline(directions[i].polyline)
//                    .stroke(Defaults.routeColor[i], lineWidth: Defaults.routeWidth)
//            }
        }
        .ignoresSafeArea()
        .sheet(
            isPresented: $showSearch,
            content: {
                SearchView(
                    directions: $directions, stepLength: $stepLength,
                    locationManager: locationManager, destination: $destination
                )
                .ignoresSafeArea()
            }
        )
        .mapControls {
            // TODO: make sure the user location stays on the map even if camera moves
            MapUserLocationButton()
                .onTapGesture {
                    zoomUserLocation()
                }
            MapCompass()
        }
        .onAppear {
            zoomUserLocation()
            Task {
                await healthKitManager.requestAccess()
                stepLength = await healthKitManager.getStepLength()
            }
        }
        .onChange(of: locationManager.location) {
            zoomUserLocation()
        }
    }
    
    func zoomUserLocation() {
        withAnimation {
            locationManager.requestAuthorization()
            locationManager.requestLocation()
            if let userLocation = locationManager.location {
                position = .camera(MapCamera(centerCoordinate: userLocation, distance: 1000))
            }
        }

    }
    
    func getLastPointFor(route: MKRoute) -> CLLocationCoordinate2D? {
        let pointCount =  route.polyline.pointCount
        if pointCount > 0 {
            return route.polyline.points()[pointCount - 1].coordinate
        }
        return nil
    }

    func save(value: String) {
        viewModel.saveValue(value)
    }
}
#Preview {
    ContentView()
}
