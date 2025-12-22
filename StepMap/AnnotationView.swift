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
    var pointOfInterestCategory: MKPointOfInterestCategory?
    @ObservedObject var viewModel: ViewModel
    
    @State private var distance: CLLocationDistance?
    @State private var localDirections: [MKRoute] = []
    @State private var isLoadingRoute = false
    @State private var showDetails = false
    @State private var shouldSetAsDestination = false
    
    private var displayTitle: String {
        title ?? pm.areasOfInterest?.first ?? pm.name ?? "\(coordinate.coordinate.latitude.description)º, \(coordinate.coordinate.longitude.description)"
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.thinMaterial)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Drag indicator
                    HStack {
                        Spacer()
                        Capsule()
                            .fill(Color(.systemGray4))
                            .frame(width: 36, height: 5)
                        Spacer()
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    
                    // Header
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(displayTitle)
                                .font(.title2)
                                .bold()
                                .lineLimit(2)
                            
                            if let address = formatSubtitle() {
                                Text(address)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Button(action: {
                            viewModel.showDetails = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    
                    // Stats Preview Card
                    StatsPreviewCard(
                        distance: distance,
                        expectedTime: localDirections.first?.expectedTravelTime,
                        stepLength: viewModel.stepLength,
                        isLoading: isLoadingRoute
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    
                    // Collapsible Details
                    if hasDetails() {
                        DisclosureGroup(isExpanded: $showDetails) {
                            VStack(alignment: .leading, spacing: 8) {
                                if let name = pm.name, name != pm.locality {
                                    DetailRow(label: "Name", value: name)
                                }
                                if let street = pm.thoroughfare {
                                    let fullStreet = [pm.subThoroughfare, street].compactMap { $0 }.joined(separator: " ")
                                    DetailRow(label: "Street", value: fullStreet)
                                }
                                if let postalCode = pm.postalCode {
                                    DetailRow(label: "Postal Code", value: postalCode)
                                }
                                if let city = pm.locality {
                                    DetailRow(label: "City", value: city)
                                }
                                if let country = pm.country {
                                    DetailRow(label: "Country", value: country)
                                }
                            }
                            .padding(.top, 8)
                        } label: {
                            HStack {
                                Image(systemName: "info.circle")
                                Text("Location Details")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        // Add as Stop button (secondary)
                        Button(action: addAsWaypoint) {
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
                        }
                        
                        // Go Here button (primary)
                        Button(action: setAsDestination) {
                            HStack {
                                Spacer()
                                if isLoadingRoute && localDirections.isEmpty {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                    Text("Go Here")
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            calculateEstimates()
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatSubtitle() -> String? {
        let components = [
            pm.thoroughfare,
            pm.locality,
            pm.administrativeArea
        ].compactMap { $0 }
        
        if components.isEmpty { return nil }
        return components.joined(separator: ", ")
    }
    
    private func hasDetails() -> Bool {
        return pm.name != nil || pm.thoroughfare != nil || pm.postalCode != nil || pm.country != nil
    }
    
    private func createMapItem() -> MKMapItem {
        let mkPlacemark = MKPlacemark(coordinate: coordinate.coordinate)
        let mapItem = MKMapItem(placemark: mkPlacemark)
        mapItem.name = title ?? pm.name
        mapItem.pointOfInterestCategory = pointOfInterestCategory
        return mapItem
    }
    
    private func addAsWaypoint() {
        let mapItem = createMapItem()
        viewModel.addWaypoint(mapItem)
        viewModel.showDetails = false
        
        // Recalculate route with new waypoint
        Task {
            let routes = await RouteService.calculateRoute(
                from: nil,
                waypoints: viewModel.waypoints
            )
            await MainActor.run {
                viewModel.routeLegs = routes
            }
        }
    }
    
    private func setAsDestination() {
        if localDirections.isEmpty {
            isLoadingRoute = true
            shouldSetAsDestination = true
            findDirections()
        } else {
            viewModel.clearRoute()
            let mapItem = createMapItem()
            viewModel.addWaypoint(mapItem)
            viewModel.routeLegs = localDirections
            viewModel.showDetails = false
        }
    }
    
    private func calculateEstimates() {
        // Calculate straight-line distance for immediate estimate
        if let userLocation = CLLocationManager().location {
            let straightLineDistance = userLocation.distance(from: coordinate)
            // Multiply by ~1.3 for walking route estimate
            self.distance = straightLineDistance * 1.3
        }
        
        // Then get actual route distance
        findDirections()
    }
    
    private func findDirections() {
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
        searchDirections.calculate { response, error in
            isLoadingRoute = false
            guard let response = response else {
                print("Error while searching for directions: \(error?.localizedDescription ?? "")")
                return
            }
            self.localDirections = response.routes
            if let route = response.routes.first {
                self.distance = route.distance
            }
            
            // If user tapped "Go Here" and we were waiting for directions
            if self.shouldSetAsDestination && !response.routes.isEmpty {
                self.shouldSetAsDestination = false
                viewModel.clearRoute()
                let mapItem = createMapItem()
                viewModel.addWaypoint(mapItem)
                viewModel.routeLegs = response.routes
                viewModel.showDetails = false
            }
        }
    }
}

// MARK: - Stats Preview Card
struct StatsPreviewCard: View {
    let distance: CLLocationDistance?
    let expectedTime: TimeInterval?
    let stepLength: Double?
    let isLoading: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            // STEPS - Primary
            VStack(spacing: 4) {
                if isLoading {
                    ProgressView()
                        .frame(height: 36)
                } else if let distance = distance, let stepLength = stepLength, stepLength > 0 {
                    let steps = Int(distance / stepLength)
                    Text(Formatters.formatNumber(steps))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                } else if let distance = distance {
                    Text(Formatters.formatDistance(distance))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                } else {
                    Text("--")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                
                Label("steps", systemImage: "figure.walk")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            Divider().frame(height: 45)
            
            // TIME - Secondary
            VStack(spacing: 4) {
                if isLoading {
                    ProgressView()
                        .frame(height: 24)
                } else if let time = expectedTime {
                    Text(Formatters.formatWalkingTime(time))
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                } else if let distance = distance {
                    // Estimate time: ~5km/h walking speed
                    let estimatedTime = distance / (5000 / 3600) // meters per second
                    Text(Formatters.formatWalkingTime(estimatedTime))
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                } else {
                    Text("--")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                
                Label("walking", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            Divider().frame(height: 45)
            
            // DISTANCE - Tertiary
            VStack(spacing: 4) {
                if isLoading {
                    ProgressView()
                        .frame(height: 18)
                } else if let distance = distance {
                    Text(Formatters.formatDistance(distance))
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                } else {
                    Text("--")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                
                Label("distance", systemImage: "arrow.forward")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .foregroundStyle(.primary)
            Spacer()
        }
        .font(.subheadline)
    }
}
