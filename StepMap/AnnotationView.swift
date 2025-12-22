//
//  AnnotationView.swift
//  StepMap
//
//  Created by Oliver Hnat on 16/05/2025.
//

import SwiftUI
import MapKit

struct AnnotationView: View {
    var pm: CLPlacemark
    var title: String?
    var coordinate: CLLocation
    @ObservedObject var viewModel: ViewModel
    
    @State private var distance: CLLocationDistance?
    @State private var localDirections: [MKRoute] = []
    @State private var showSteps = true
    @State private var isLoadingRoute = false
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.thinMaterial)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header with title and close button
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text((title ?? pm.areasOfInterest?.first ?? pm.name) ?? "\(coordinate.coordinate.latitude.description)º, \(coordinate.coordinate.longitude.description)")
                                .font(.title2)
                                .bold()
                            
                            if let locality = pm.locality {
                                Text(locality)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Button(action: {
                            viewModel.showDetails = false
                        }, label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        })
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Location details
                    VStack(alignment: .leading, spacing: 8) {
                        if let name = pm.name, name != pm.locality {
                            DetailRow(label: "Name", value: name)
                        }
                        if let street = pm.thoroughfare {
                            let fullStreet = [street, pm.subThoroughfare].compactMap { $0 }.joined(separator: " ")
                            DetailRow(label: "Street", value: fullStreet)
                        }
                        if let postalCode = pm.postalCode {
                            DetailRow(label: "Postal Code", value: postalCode)
                        }
                        if let country = pm.country {
                            DetailRow(label: "Country", value: country)
                        }
                        if let areas = pm.areasOfInterest, !areas.isEmpty {
                            ForEach(areas, id: \.self) { area in
                                DetailRow(label: "Area", value: area)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Distance display
                    if let distance = distance {
                        HStack {
                            Image(systemName: "figure.walk")
                                .foregroundStyle(.blue)
                            Button {
                                showSteps.toggle()
                            } label: {
                                Text(formatDistance(distance: distance))
                                    .font(.headline)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        // Add as Stop button
                        Button(action: {
                            addAsWaypoint()
                        }, label: {
                            HStack {
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                Text("Add as Stop")
                                Spacer()
                            }
                            .padding()
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        })
                        .padding(.horizontal)
                        
                        // Show Route button (sets this as only destination)
                        Button(action: {
                            if localDirections.isEmpty {
                                isLoadingRoute = true
                                findDirections()
                            } else {
                                // Clear existing route and set this as only destination
                                viewModel.clearRoute()
                                let mapItem = createMapItem()
                                viewModel.addWaypoint(mapItem)
                                viewModel.routeLegs = localDirections
                            }
                        }, label: {
                            HStack {
                                Spacer()
                                if isLoadingRoute && localDirections.isEmpty {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                    Text(localDirections.isEmpty ? "Show Route" : "Set as Destination")
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        })
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func createMapItem() -> MKMapItem {
        let mkPlacemark = MKPlacemark(coordinate: coordinate.coordinate)
        let mapItem = MKMapItem(placemark: mkPlacemark)
        mapItem.name = title ?? pm.name
        return mapItem
    }
    
    private func addAsWaypoint() {
        let mapItem = createMapItem()
        viewModel.addWaypoint(mapItem)
        viewModel.showDetails = false
        
        // Recalculate route with new waypoint
        Task {
            let routes = await RouteService.calculateRoute(
                from: nil, // Will use current location
                waypoints: viewModel.waypoints
            )
            await MainActor.run {
                viewModel.routeLegs = routes
            }
        }
    }
    
    func formatDistance(distance: CLLocationDistance) -> String {
        let steps = distance / (viewModel.stepLength ?? 1)
        if steps != 0 && showSteps {
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 0
            formatter.numberStyle = .decimal
            let number = NSNumber(value: steps)
            return formatter.string(from: number)! + " steps"
        }
        let distanceFormatter = MKDistanceFormatter()
        return distanceFormatter.string(fromDistance: distance)
    }
    
    func findDirections() {
        let directionsRequest = MKDirections.Request()
        directionsRequest.source = MKMapItem.forCurrentLocation()
        
        let mkPlacemark = MKPlacemark(coordinate: coordinate.coordinate)
        let destination = MKMapItem(placemark: mkPlacemark)
        destination.name = title ?? pm.name
        
        directionsRequest.destination = destination
        directionsRequest.transportType = .walking
        directionsRequest.requestsAlternateRoutes = false
        directionsRequest.departureDate = .now
        
        let searchDirections = MKDirections(request: directionsRequest)
        searchDirections.calculate { (response, error) in
            isLoadingRoute = false
            guard let response = response else {
                print("Error while searching for directions: \(error?.localizedDescription ?? "")")
                return
            }
            self.localDirections = response.routes
            self.distance = response.routes.first?.distance
            
            // Clear existing route and set this as only destination
            viewModel.clearRoute()
            viewModel.addWaypoint(destination)
            viewModel.routeLegs = response.routes
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(value)
            Spacer()
        }
    }
}
