//
//  WaypointSearchView.swift
//  StepMap
//
//  Created by Oliver Hnat on 22/12/2024.
//

import SwiftUI
import MapKit

struct WaypointSearchView: View {
    @ObservedObject var viewModel: ViewModel
    var locationManager: LocationManager
    var onWaypointSelected: (MKMapItem) -> Void
    
    @State private var query: String = ""
    @State private var searchResults: [MKMapItem] = []
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search field
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search for a place", text: $query)
                        .autocorrectionDisabled()
                        .focused($isSearchFocused)
                        .onChange(of: query) {
                            if query.count > 0 {
                                search(for: query)
                            } else {
                                searchResults = []
                            }
                        }
                    
                    if !query.isEmpty {
                        Button(action: { query = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
                .onAppear {
                    isSearchFocused = true
                }
                
                Divider()
                
                // Results
                if searchResults.isEmpty && query.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundStyle(.tertiary)
                        Text("Search for places")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Find destinations, landmarks, or addresses")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding()
                } else if searchResults.isEmpty && !query.isEmpty {
                    // No results
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "mappin.slash")
                            .font(.system(size: 40))
                            .foregroundStyle(.tertiary)
                        Text("No results found")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Try a different search term")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                        Spacer()
                    }
                    .padding()
                } else {
                    // Results list
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(searchResults, id: \.identifier) { item in
                                SearchResultRow(
                                    item: item,
                                    userLocation: locationManager.location,
                                    stepLength: viewModel.stepLength,
                                    onSelect: {
                                        onWaypointSelected(item)
                                    }
                                )
                                
                                Divider()
                                    .padding(.leading, 54)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Stop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    func search(for text: String) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = text
        
        if let userCoordinate = locationManager.location {
            let region = MKCoordinateRegion(center: userCoordinate, latitudinalMeters: 50000, longitudinalMeters: 50000)
            searchRequest.region = region
        }
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let response = response else { return }
            
            var items = response.mapItems
            if let userCoordinate = locationManager.location {
                let userLocation = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
                items.sort { item1, item2 in
                    guard let loc1 = item1.placemark.location, let loc2 = item2.placemark.location else { return false }
                    return userLocation.distance(from: loc1) < userLocation.distance(from: loc2)
                }
            }
            self.searchResults = items
        }
    }
}

// MARK: - Search Result Row
struct SearchResultRow: View {
    let item: MKMapItem
    let userLocation: CLLocationCoordinate2D?
    let stepLength: Double?
    var onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // POI icon with colored background
                ZStack {
                    Circle()
                        .fill(Defaults.getColorFor(pointOfInterest: item.pointOfInterestCategory).opacity(0.15))
                        .frame(width: 42, height: 42)
                    Image(systemName: Defaults.getIconFor(pointOfInterest: item.pointOfInterestCategory))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Defaults.getColorFor(pointOfInterest: item.pointOfInterestCategory))
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name ?? "Unknown")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    // Address
                    if let address = formatAddress() {
                        Text(address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    // Step estimate
                    if let stepsText = estimatedStepsText() {
                        HStack(spacing: 4) {
                            Image(systemName: "figure.walk")
                                .font(.system(size: 10))
                            Text(stepsText)
                        }
                        .font(.caption)
                        .foregroundStyle(.green)
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func formatAddress() -> String? {
        let components = [
            item.placemark.thoroughfare,
            item.placemark.locality
        ].compactMap { $0 }
        
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
    
    private func estimatedStepsText() -> String? {
        guard let userLocation = userLocation,
              let itemLocation = item.placemark.location else { return nil }
        
        let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let distance = userCLLocation.distance(from: itemLocation)
        
        // Straight-line distance, multiply by ~1.3 for walking estimate
        let estimatedWalkingDistance = distance * 1.3
        
        if let stepLength = stepLength, stepLength > 0 {
            let steps = Int(estimatedWalkingDistance / stepLength)
            return "~\(Formatters.formatNumber(steps)) steps"
        } else {
            // Fallback: show distance
            return "~\(Formatters.formatDistance(estimatedWalkingDistance))"
        }
    }
}
