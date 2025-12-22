//
//  WaypointRowView.swift
//  StepMap
//
//  Created by Oliver Hnat on 22/12/2024.
//

import SwiftUI
import MapKit

struct WaypointRowView: View {
    let waypoint: MKMapItem
    let index: Int
    let leg: MKRoute?
    let stepLength: Double?
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Waypoint marker
            VStack(spacing: 0) {
                // Connection line from previous
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 2, height: 10)
                
                // Waypoint circle
                ZStack {
                    Circle()
                        .fill(isLast ? Color.red : Color.blue)
                        .frame(width: 24, height: 24)
                    Text("\(index + 1)")
                        .font(.caption2)
                        .bold()
                        .foregroundStyle(.white)
                }
                
                // Connection line to next (if not last)
                if !isLast {
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 2, height: 30)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Waypoint name
                Text(waypoint.name ?? "Unknown Location")
                    .font(.headline)
                
                // Address
                if let locality = waypoint.placemark.locality {
                    Text(locality)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Leg stats (time & steps to reach this waypoint)
                if let leg = leg {
                    HStack(spacing: 16) {
                        Label(Formatters.formatWalkingTime(leg.expectedTravelTime), systemImage: "clock")
                        
                        if let stepLength = stepLength, stepLength > 0 {
                            let steps = Int(leg.distance / stepLength)
                            Label(Formatters.formatNumber(steps) + " steps", systemImage: "figure.walk")
                        }
                        
                        Label(Formatters.formatDistance(leg.distance), systemImage: "arrow.forward")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
