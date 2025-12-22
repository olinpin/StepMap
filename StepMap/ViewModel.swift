//
//  ViewModel.swift
//  StepMap
//
//  Created by Oliver Hnát on 23.11.2024.
//

import Foundation
import MapKit

class ViewModel: ObservableObject {
    @Published var test: String = UserDefaults.standard.string(forKey: "test") ?? ""
    @Published var stepLength: Double?
    @Published var showDetails = false
    
    // MARK: - Waypoint-based routing
    @Published var waypoints: [MKMapItem] = []  // Ordered list of stops
    @Published var routeLegs: [MKRoute] = []    // Route between each waypoint pair
    @Published var shouldZoomToRoute = false    // Whether to zoom when route updates
    
    // Computed property: all polylines for map display (backwards compatibility)
    var directions: [MKRoute] {
        return routeLegs
    }
    
    // Legacy destination property for backwards compatibility
    var destination: MKMapItem? {
        return waypoints.last
    }
    
    // MARK: - Computed totals
    var totalDistance: CLLocationDistance {
        routeLegs.reduce(0) { $0 + $1.distance }
    }
    
    var totalTime: TimeInterval {
        routeLegs.reduce(0) { $0 + $1.expectedTravelTime }
    }
    
    var totalSteps: Int? {
        guard let stepLength = stepLength, stepLength > 0 else { return nil }
        return Int(totalDistance / stepLength)
    }
    
    // MARK: - Waypoint management
    func addWaypoint(_ item: MKMapItem) {
        waypoints.append(item)
    }
    
    func removeWaypoint(at index: Int) {
        guard index < waypoints.count else { return }
        waypoints.remove(at: index)
    }
    
    func moveWaypoint(from source: IndexSet, to destination: Int) {
        waypoints.move(fromOffsets: source, toOffset: destination)
    }
    
    func clearRoute() {
        waypoints.removeAll()
        routeLegs.removeAll()
    }
    
    func saveValue(_ value: String) {
        UserDefaults.standard.set(value, forKey: "test")
        test = value
    }
}
