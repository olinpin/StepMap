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
    @Binding var directions: [MKRoute]

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search for any location", text: $query)
                    .autocorrectionDisabled()
                    .onChange(of: self.query) {
                        search(for: self.query)
                    }
            }
            .modifier(TextFieldGrayBackgroudColor())
            Spacer()
            List(self.locations, id: \.identifier) { location in
                Button(
                    action: {
                        self.findDirections(to: location)
                    },
                    label: {
                        SearchItemView(location: location)
                    })
            }
        }
        .padding()
        .interactiveDismissDisabled()

        .presentationDetents([.height(200), .large])
        .presentationBackground(.regularMaterial)
        .presentationBackgroundInteraction(.enabled(upThrough: .large))
    }

    func findDirections(to place: MKMapItem) {
        let directionsRequest = MKDirections.Request()
        //        directionsRequest.source = MKMapItem.forCurrentLocation()
        directionsRequest.source = MKMapItem.init(
            placemark: MKPlacemark(
                coordinate: CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041)))
        directionsRequest.destination = place
        directionsRequest.transportType = .walking
        directionsRequest.requestsAlternateRoutes = false  // TODO: make alternative routes available
        directionsRequest.departureDate = .now

        let searchDirections = MKDirections(request: directionsRequest)
        searchDirections.calculate { (response, error) in
            guard let response = response else {
                print(error)
                print("Error while searching for directions")
                return
            }
            self.directions = response.routes
        }
    }

    func search(for text: String) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = text

        let search = MKLocalSearch(request: searchRequest)
        search.start { (response, error) in
            guard let response = response else {
                print("ERROR")
                return
            }
            var items: [MKMapItem] = []
            for item in response.mapItems {
                if let name = item.name,
                    let location = item.placemark.location
                {
                    print(
                        "\(name): \(location.coordinate.latitude),\(location.coordinate.longitude)")
                    items.append(item)
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

#Preview {
    @Previewable @State var directions: [MKRoute] = []
    return SearchView(directions: $directions)
}
