//
//  RouteService.swift
//  StepMap
//
//  Created by Oliver Hnat on 22/12/2024.
//

import MapKit

class RouteService {
    
    /// Calculates walking routes between consecutive waypoints
    /// Returns array of MKRoute for each leg (start->waypoint[0], waypoint[0]->waypoint[1], etc.)
    static func calculateRoute(from start: CLLocationCoordinate2D?, waypoints: [MKMapItem]) async -> [MKRoute] {
        guard !waypoints.isEmpty else { return [] }
        
        var routes: [MKRoute] = []
        var previousLocation: MKMapItem
        
        // Start from current location or first waypoint
        if let startCoord = start {
            previousLocation = MKMapItem(placemark: MKPlacemark(coordinate: startCoord))
        } else {
            previousLocation = MKMapItem.forCurrentLocation()
        }
        
        // Calculate route for each leg
        for waypoint in waypoints {
            if let route = await calculateLeg(from: previousLocation, to: waypoint) {
                routes.append(route)
            }
            previousLocation = waypoint
        }
        
        return routes
    }
    
    private static func calculateLeg(from source: MKMapItem, to destination: MKMapItem) async -> MKRoute? {
        let request = MKDirections.Request()
        request.source = source
        request.destination = destination
        request.transportType = .walking
        request.requestsAlternateRoutes = false
        
        let directions = MKDirections(request: request)
        
        do {
            let response = try await directions.calculate()
            return response.routes.first
        } catch {
            print("Error calculating route leg: \(error.localizedDescription)")
            return nil
        }
    }
}
