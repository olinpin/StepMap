//
//  SearchView.swift
//  StepMap
//
//  Created by Oliver Hnát on 23.11.2024.
//

import MapKit
import SwiftUI

struct SearchView: View {
    @State private var query: String = ""
    @State private var locations: [MKMapItem] = []
    @State var showSteps = true
    var locationManager: LocationManager
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.thinMaterial)
                .ignoresSafeArea()
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search for any location", text: $query)
                        .autocorrectionDisabled()
                        .onChange(of: self.query) {
                            if query.count > 0 {
                                search(for: self.query)
                            } else {
                                self.locations = []
                            }
                        }
                    //                                        .onAppear {
                    //                                            // TODO: delete this, it's for debug only
                    //                                            search(for: self.query)
                    //                                        }
                        .overlay {
                            HStack {
                                Spacer()
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundStyle(.gray)
                                    .onTapGesture {
                                        query = ""
                                        viewModel.destination = nil
                                        viewModel.directions = []
                                    }
                            }
                        }
                }
                .modifier(TextFieldGrayBackgroudColor())
                Spacer()
                ScrollView {
                    ForEach(self.locations, id: \.identifier) { location in
                        SearchItemView(location: location, showSteps: $showSteps, viewModel: viewModel)
                    }
                }
            }
            .padding()
            .interactiveDismissDisabled()
            .ignoresSafeArea()
        }
    }

    func search(for text: String) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = text
        
        // Bias search results to the user's current location
        if let userCoordinate = locationManager.location {
            let region = MKCoordinateRegion(
                center: userCoordinate,
                latitudinalMeters: 50000,  // Search within 50km radius
                longitudinalMeters: 50000
            )
            searchRequest.region = region
        }

        let search = MKLocalSearch(request: searchRequest)
        search.start { (response, error) in
            guard let response = response else {
                print(error)
                return
            }
            var items: [MKMapItem] = []
            for item in response.mapItems {
                if let name = item.name,
                    let location = item.placemark.location
                {
                    items.append(item)
                }
            }
            
            // Sort results by distance from user's current location
            if let userCoordinate = locationManager.location {
                let userLocation = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
                items.sort { item1, item2 in
                    guard let loc1 = item1.placemark.location,
                          let loc2 = item2.placemark.location else {
                        return false
                    }
                    let distance1 = userLocation.distance(from: loc1)
                    let distance2 = userLocation.distance(from: loc2)
                    return distance1 < distance2
                }
            }
            
            self.locations = items
        }
    }
}

struct TextFieldGrayBackgroudColor: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(10)
            .background(.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(.primary)
    }
}

//#Preview {
//    @Previewable @State var directions: [MKRoute] = []
//    @Previewable @State var displayRoute: Bool = false
//    return SearchView(directions: $directions, $disp)
//}
