//
//  RouteStatsView.swift
//  StepMap
//
//  Created by Oliver Hnat on 22/12/2024.
//

import SwiftUI
import MapKit

struct RouteStatsView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Walking Time (primary)
            VStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
                Text(Formatters.formatWalkingTime(viewModel.totalTime))
                    .font(.headline)
                    .bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("walk time")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 50)
            
            // Steps (primary)
            VStack(spacing: 4) {
                Image(systemName: "figure.walk")
                    .font(.title3)
                    .foregroundStyle(.green)
                if let steps = viewModel.totalSteps {
                    Text(Formatters.formatNumber(steps))
                        .font(.headline)
                        .bold()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                } else {
                    Text("--")
                        .font(.headline)
                        .bold()
                }
                Text("steps")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 50)
            
            // Distance (secondary)
            VStack(spacing: 4) {
                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                    .font(.title3)
                    .foregroundStyle(.orange)
                Text(Formatters.formatDistance(viewModel.totalDistance))
                    .font(.headline)
                    .bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("distance")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemBackground).opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
