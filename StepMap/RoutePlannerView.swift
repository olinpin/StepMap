//
//  RoutePlannerView.swift
//  StepMap
//
//  Created by Oliver Hnat on 22/12/2024.
//

import SwiftUI
import MapKit

struct RoutePlannerView: View {
    @ObservedObject var viewModel: ViewModel
    var locationManager: LocationManager
    @State private var showingSearch = false
    @State private var isCalculating = false
    @State private var showingHealthInfo = false
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.thinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Health info button
                HStack {
                    Spacer()
                    Button(action: { showingHealthInfo = true }) {
                        Image(systemName: "heart.text.square")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.trailing, 12)
                }
                .padding(.top, 6)
                .padding(.bottom, 8)
                
                if viewModel.waypoints.isEmpty {
                    EmptyRouteView(showingSearch: $showingSearch)
                } else {
                    RouteActiveView(
                        viewModel: viewModel,
                        isCalculating: isCalculating,
                        showingSearch: $showingSearch,
                        onDelete: { index in
                            viewModel.removeWaypoint(at: index)
                            recalculateRoute()
                        },
                        onMove: { from, to in
                            viewModel.moveWaypoint(from: from, to: to)
                            recalculateRoute()
                        },
                        onClearRoute: {
                            viewModel.clearRoute()
                        }
                    )
                }
            }
        }
        .sheet(isPresented: $showingSearch) {
            WaypointSearchView(
                viewModel: viewModel,
                locationManager: locationManager,
                onWaypointSelected: { waypoint in
                    viewModel.addWaypoint(waypoint)
                    viewModel.shouldZoomToRoute = true  // Zoom when adding via search
                    showingSearch = false
                    recalculateRoute()
                }
            )
        }
        .sheet(isPresented: $showingHealthInfo) {
            HealthInfoView(viewModel: viewModel)
        }
    }
    
    private func recalculateRoute() {
        isCalculating = true
        Task {
            let routes = await RouteService.calculateRoute(
                from: locationManager.location,
                waypoints: viewModel.waypoints
            )
            await MainActor.run {
                viewModel.routeLegs = routes
                isCalculating = false
            }
        }
    }
}

// MARK: - Empty Route View
struct EmptyRouteView: View {
    @Binding var showingSearch: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: { showingSearch = true }) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    Text("Search destination")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal, 12)
            
            Spacer()
        }
    }
}

// MARK: - Route Active View
struct RouteActiveView: View {
    @ObservedObject var viewModel: ViewModel
    var isCalculating: Bool
    @Binding var showingSearch: Bool
    var onDelete: (Int) -> Void
    var onMove: (IndexSet, Int) -> Void
    var onClearRoute: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Hero Stats
            HeroStatsView(viewModel: viewModel, isCalculating: isCalculating)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            
            Divider()
            
            // Waypoints ScrollView
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    // Starting point
                    StartingPointRow()
                    
                    // Waypoints
                    ForEach(Array(viewModel.waypoints.enumerated()), id: \.offset) { index, waypoint in
                        WaypointRowView(
                            waypoint: waypoint,
                            index: index,
                            leg: index < viewModel.routeLegs.count ? viewModel.routeLegs[index] : nil,
                            stepLength: viewModel.stepLength,
                            isLast: index == viewModel.waypoints.count - 1,
                            onDelete: { onDelete(index) }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
            }
            
            // Bottom Actions
            BottomActionsView(
                showingSearch: $showingSearch,
                onClearRoute: onClearRoute
            )
        }
    }
}

// MARK: - Hero Stats View
struct HeroStatsView: View {
    @ObservedObject var viewModel: ViewModel
    var isCalculating: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            // STEPS - Primary
            VStack(spacing: 4) {
                if isCalculating {
                    ProgressView()
                        .frame(height: 43)
                } else if let steps = viewModel.totalSteps {
                    Text(Formatters.formatNumber(steps))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                } else {
                    Text("--")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Label("steps", systemImage: "figure.walk")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            Divider().frame(height: 50)
            
            // TIME - Secondary
            VStack(spacing: 4) {
                if isCalculating {
                    ProgressView()
                        .frame(height: 29)
                } else {
                    Text(Formatters.formatWalkingTime(viewModel.totalTime))
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                }
                Label("walking", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            Divider().frame(height: 50)
            
            // DISTANCE - Tertiary
            VStack(spacing: 4) {
                if isCalculating {
                    ProgressView()
                        .frame(height: 22)
                } else {
                    Text(Formatters.formatDistance(viewModel.totalDistance))
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Label("distance", systemImage: "arrow.forward")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Starting Point Row
struct StartingPointRow: View {
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Timeline indicator
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 24, height: 24)
                    Image(systemName: "location.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.white)
                }
                
                // Connection line to next
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 2, height: 24)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Your Location")
                    .font(.headline)
                Text("Starting point")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Bottom Actions View
struct BottomActionsView: View {
    @Binding var showingSearch: Bool
    var onClearRoute: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Add Stop Button
            Button(action: { showingSearch = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Stop")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Clear Route Button
            Button(action: onClearRoute) {
                Image(systemName: "trash.fill")
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .foregroundStyle(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }
}
