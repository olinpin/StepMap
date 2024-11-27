//
//  SearchItemView.swift
//  StepMap
//
//  Created by Oliver Hnát on 23.11.2024.
//

import HealthKit
import HealthKitUI
import MapKit
import SwiftUI

struct SearchItemView: View {
    var location: MKMapItem
    @State var distance: CLLocationDistance?
    @Binding var directions: [MKRoute]
    @Binding var stepLength: Double?
    @Binding var showSteps: Bool
    @State var localDirections: [MKRoute] = []

    var body: some View {

        Button(
            action: {
                if localDirections == [] {
                    findDirections()
                }
                directions = localDirections
            },
            label: {
                HStack {
                    Circle()
                        .padding()
                        .overlay(alignment: .center) {
                            Image(
                                systemName: Defaults.getIconFor(
                                    pointOfInterest: location.pointOfInterestCategory)
                            )
                            .foregroundStyle(.white)
                            .font(.title)
                        }
                        .foregroundStyle(
                            Defaults.getColorFor(pointOfInterest: location.pointOfInterestCategory))
                    HStack {
                        VStack {
                            HStack {
                                Text("\(location.name ?? "")")
                                    .foregroundStyle(.black)
                                    .font(.title3)
                                    .lineLimit(1)
                                Spacer()
                            }
                            HStack {
                                Text("\(location.placemark.locality ?? "")")
                                    //                    .font(.)
                                    .foregroundStyle(.gray)
                                Spacer()
                            }
                        }
                        if distance != nil {
                            Button {
                                self.showSteps.toggle()
                            } label: {
                                Text("\(formatDistance(distance: distance!))")
                            }
                        }
                    }
                    Spacer()
                }
            }
        )
        .frame(height: 100)
//        .onAppear {
//            findDirections()
//        }
    }

    func formatDistance(distance: CLLocationDistance) -> String {
        let steps = distance * (stepLength ?? 0)
        if steps != 0 && showSteps {
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 0
            formatter.numberStyle = .decimal
            let number = NSNumber(value: steps)
            return formatter.string(from: number)! + " steps"
            //            return String(format: "%.0f", steps)
        }
        let distanceFormatter = MKDistanceFormatter()
        return distanceFormatter.string(fromDistance: distance)
    }

    func findDirections() {
        let directionsRequest = MKDirections.Request()
        directionsRequest.source = MKMapItem.forCurrentLocation()
        //                directionsRequest.source = MKMapItem.init(
        //                    placemark: MKPlacemark(
        //                        coordinate: CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041)))
        directionsRequest.destination = location
        directionsRequest.transportType = .walking
        directionsRequest.requestsAlternateRoutes = false  // TODO: make alternative routes available
        directionsRequest.departureDate = .now

        let searchDirections = MKDirections(request: directionsRequest)
        searchDirections.calculate { (response, error) in
            guard let response = response else {
                print("Error while searching for directions: \(error?.localizedDescription ?? "")")
                return
            }
            self.localDirections = response.routes
            self.distance = response.routes.first?.distance
        }
    }
}
