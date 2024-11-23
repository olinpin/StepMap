//
//  SearchView.swift
//  StepMap
//
//  Created by Oliver Hnát on 23.11.2024.
//

import SwiftUI
import MapKit

struct SearchView: View {
    @State private var query: String = ""
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
            Text("\($query.wrappedValue)")
            Spacer()
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
                print("ERROR")
                return
            }
            for item in response.mapItems {
                if let name = item.name,
                   let location = item.placemark.location {
                    print("\(name): \(location.coordinate.latitude),\(location.coordinate.longitude)")
                }
            }
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
    SearchView()
}
