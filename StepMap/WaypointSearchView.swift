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
    
    var body: some View {
        NavigationView {
            VStack {
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search for a place", text: $query)
                        .autocorrectionDisabled()
                        .onChange(of: query) {
                            if query.count > 0 {
                                search(for: query)
                            } else {
                                searchResults = []
                            }
                        }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()
                
                // Results
                List(searchResults, id: \.identifier) { item in
                    Button(action: {
                        onWaypointSelected(item)
                    }) {
                        HStack {
                            Image(systemName: Defaults.getIconFor(pointOfInterest: item.pointOfInterestCategory))
                                .foregroundStyle(Defaults.getColorFor(pointOfInterest: item.pointOfInterestCategory))
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text(item.name ?? "Unknown")
                                    .foregroundStyle(.primary)
                                if let locality = item.placemark.locality {
                                    Text(locality)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
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
