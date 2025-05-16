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
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.thinMaterial)
                .ignoresSafeArea()
            VStack {
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
        }
    }
}
