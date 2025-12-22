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
    var onDelete: (() -> Void)?
    
    @State private var offset: CGFloat = 0
    @State private var showDeleteButton = false
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete button background
            if showDeleteButton {
                Button(action: {
                    // Reset state immediately before deleting
                    offset = 0
                    showDeleteButton = false
                    onDelete?()
                }) {
                    Image(systemName: "trash.fill")
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .transition(.move(edge: .trailing))
            }
            
            // Main content
            HStack(alignment: .top, spacing: 12) {
                // Timeline indicator
                VStack(spacing: 0) {
                    // Connection line from previous
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 2, height: 12)
                    
                    // Waypoint circle
                    ZStack {
                        Circle()
                            .fill(isLast ? Color.red : Color.blue)
                            .frame(width: 28, height: 28)
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    
                    // Connection line to next (if not last)
                    if !isLast {
                        Rectangle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 2, height: 40)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    // Location name
                    Text(waypoint.name ?? "Unknown Location")
                        .font(.headline)
                        .lineLimit(2)
                    
                    // Address
                    if let address = formatAddress() {
                        Text(address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    // Leg stats card
                    if let leg = leg {
                        LegStatsCard(leg: leg, stepLength: stepLength)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
            .background(Color(.systemBackground).opacity(0.001)) // For gesture detection
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < 0 {
                            offset = value.translation.width
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if value.translation.width < -50 {
                                offset = -70
                                showDeleteButton = true
                            } else {
                                offset = 0
                                showDeleteButton = false
                            }
                        }
                    }
            )
            .onTapGesture {
                if showDeleteButton {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        offset = 0
                        showDeleteButton = false
                    }
                }
            }
        }
    }
    
    private func formatAddress() -> String? {
        let components = [
            waypoint.placemark.thoroughfare,
            waypoint.placemark.locality
        ].compactMap { $0 }
        
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
}

// MARK: - Leg Stats Card
struct LegStatsCard: View {
    let leg: MKRoute
    let stepLength: Double?
    
    var body: some View {
        HStack(spacing: 16) {
            // Steps - Primary (Green)
            if let stepLength = stepLength, stepLength > 0 {
                let steps = Int(leg.distance / stepLength)
                HStack(spacing: 4) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.green)
                    Text(Formatters.formatSteps(steps))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                }
            }
            
            // Time - Secondary (Blue)
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 11))
                    .foregroundStyle(.blue)
                Text(Formatters.formatTimeCompact(leg.expectedTravelTime))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            // Distance - Tertiary (Muted)
            HStack(spacing: 4) {
                Image(systemName: "arrow.forward")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text(Formatters.formatDistance(leg.distance))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
