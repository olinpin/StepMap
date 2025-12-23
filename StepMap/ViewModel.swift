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
    @Published var walkingSpeed: Double?
    @Published var showDetails = false
    
    // MARK: - Step Length Override
    @Published var stepLengthSource: StepLengthSource?
    @Published var stepLengthOverride: Double? {
        didSet {
            if let override = stepLengthOverride {
                UserDefaults.standard.set(override, forKey: "stepLengthOverride")
            } else {
                UserDefaults.standard.removeObject(forKey: "stepLengthOverride")
            }
        }
    }
    @Published var healthKitStepLength: Double?  // Store original HealthKit value
    
    // Computed property for effective step length
    var effectiveStepLength: Double? {
        return stepLengthOverride ?? stepLength
    }
    
    // MARK: - Walking Speed Override
    @Published var walkingSpeedSource: WalkingSpeedSource?
    @Published var walkingSpeedOverride: Double? {
        didSet {
            if let override = walkingSpeedOverride {
                UserDefaults.standard.set(override, forKey: "walkingSpeedOverride")
            } else {
                UserDefaults.standard.removeObject(forKey: "walkingSpeedOverride")
            }
        }
    }
    @Published var healthKitWalkingSpeed: Double?  // Store original HealthKit value
    
    // Computed property for effective walking speed
    var effectiveWalkingSpeed: Double? {
        return walkingSpeedOverride ?? walkingSpeed
    }
    
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
        guard let stepLength = effectiveStepLength, stepLength > 0 else { return nil }
        return Int(totalDistance / stepLength)
    }
    
    // MARK: - Initializer
    init() {
        if UserDefaults.standard.object(forKey: "stepLengthOverride") != nil {
            stepLengthOverride = UserDefaults.standard.double(forKey: "stepLengthOverride")
        }
        if UserDefaults.standard.object(forKey: "walkingSpeedOverride") != nil {
            walkingSpeedOverride = UserDefaults.standard.double(forKey: "walkingSpeedOverride")
        }
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
