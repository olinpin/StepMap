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
    @Binding var stepLength: Double?
    @State var showSteps = true
    var locationManager: LocationManager

    var body: some View {
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
                    //                    .onAppear {
                    //                        // TODO: delete this, it's for debug only
                    //                        search(for: self.query)
                    //                    }
                    .overlay {
                        HStack {
                            Spacer()
                            Image(systemName: "multiply.circle.fill")
                                .foregroundStyle(.gray)
                                .onTapGesture {
                                    query = ""
                                }
                        }
                    }
            }
            .modifier(TextFieldGrayBackgroudColor())
            Spacer()
            ScrollView {
                ForEach(self.locations, id: \.identifier) { location in
                    SearchItemView(
                        location: location, directions: $directions, stepLength: $stepLength,
                        showSteps: $showSteps)
                }
            }
        }
        .padding()
        .interactiveDismissDisabled()

        .presentationDetents([.height(200), .large])
        .presentationBackground(.regularMaterial)
        .presentationBackgroundInteraction(.enabled(upThrough: .large))
    }

    func search(for text: String) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = text

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
