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
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.thinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Route Stats Header (prominently displayed)
                if !viewModel.waypoints.isEmpty {
                    RouteStatsView(viewModel: viewModel)
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                }
                
                Divider()
                
                // MARK: - Waypoints List
                if viewModel.waypoints.isEmpty {
                    // Empty state - prompt to add destination
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "map")
                            .font(.system(size: 44))
                            .foregroundStyle(.secondary)
                        Text("Plan Your Walk")
                            .font(.title3)
                            .bold()
                        Text("Search for a destination or long-press the map to start planning your route")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                        Spacer()
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    // Waypoint list with reordering
                    List {
                        // Starting point (current location)
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundStyle(.blue)
                            Text("Current Location")
                                .foregroundStyle(.secondary)
                        }
                        
                        // Waypoints (reorderable)
                        ForEach(viewModel.waypoints.indices, id: \.self) { index in
                            WaypointRowView(
                                waypoint: viewModel.waypoints[index],
                                index: index,
                                leg: index < viewModel.routeLegs.count ? viewModel.routeLegs[index] : nil,
                                stepLength: viewModel.stepLength,
                                isLast: index == viewModel.waypoints.count - 1
                            )
                        }
                        .onMove { from, to in
                            viewModel.moveWaypoint(from: from, to: to)
                            recalculateRoute()
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { viewModel.removeWaypoint(at: $0) }
                            recalculateRoute()
                        }
                    }
                    .listStyle(.plain)
                }
                
                // MARK: - Action Buttons
                HStack(spacing: 12) {
                    // Add Waypoint Button
                    Button(action: { showingSearch = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text(viewModel.waypoints.isEmpty ? "Add Destination" : "Add Stop")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Clear Route Button (only if route exists)
                    if !viewModel.waypoints.isEmpty {
                        Button(action: {
                            viewModel.clearRoute()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .foregroundStyle(.red)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingSearch) {
            WaypointSearchView(
                viewModel: viewModel,
                locationManager: locationManager,
                onWaypointSelected: { waypoint in
                    viewModel.addWaypoint(waypoint)
                    showingSearch = false
                    recalculateRoute()
                }
            )
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
