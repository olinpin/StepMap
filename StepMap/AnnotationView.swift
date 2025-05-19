//
//  AnnotationView.swift
//  StepMap
//
//  Created by Oliver Hnat on 16/05/2025.
//

import SwiftUI
import MapKit

struct AnnotationView: View {
    var pm: CLPlacemark
    var title: String?
    var coordinate: CLLocation
    @ObservedObject var viewModel: ViewModel
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.thinMaterial)
                .ignoresSafeArea()
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    Text((title ?? pm.areasOfInterest?.first ?? pm.name) ?? "\(coordinate.coordinate.latitude.description)º, \(coordinate.coordinate.longitude.description)")
                        .font(.title)
                        .bold()
                    Spacer()
                    Button(action: {
                        viewModel.showDetails = false
                        
                    }, label: {
                        Image(systemName: "multiply.circle")
                    })
                }
                .padding(.horizontal)
                .padding(.top, 20)
                Spacer()
                Text(pm.locality ?? "")
                Text(pm.name ?? "")
                Text("Name: \(pm.name ?? "")")
                Text("Street: \(pm.thoroughfare ?? "")")
                Text("City: \(pm.locality ?? "")")
                Text("Postal Code: \(pm.postalCode ?? "")")
                Text("Country: \(pm.country ?? "")")
                ForEach(pm.areasOfInterest ?? [], id: \.self) { area in
                    Text("Area: \(area)")
                }
                if let coordinate = pm.location?.coordinate {
                    let mkPlacemark = MKPlacemark(coordinate: coordinate)
                    Image(systemName: Defaults.getIconFor(pointOfInterest: MKMapItem(placemark: mkPlacemark).pointOfInterestCategory))
                }
            }
            .frame(maxWidth: .infinity)
            .ignoresSafeArea()
        }
    }
}
