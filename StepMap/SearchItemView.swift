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
    @Binding var showSteps: Bool
    @State var localDirections: [MKRoute] = []
    @ObservedObject var viewModel: ViewModel

    var body: some View {

        Button(
            action: {
                if localDirections == [] {
                    print("finding directions")
                    findDirections()
                } else {
                    // Clear existing route and set this as only destination
                    viewModel.clearRoute()
                    viewModel.addWaypoint(location)
                    viewModel.routeLegs = localDirections
                }
                print("Directions set")
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
                                VStack(alignment: .leading) {
                                    if (location.placemark.thoroughfare != nil) {
                                        Text(
                                            "\(location.placemark.thoroughfare ?? "") \(location.placemark.subThoroughfare ?? "")"
                                        )
                                        .foregroundStyle(.gray)
                                    }
                                    if (location.placemark.locality != nil) {
                                        Text("\(location.placemark.locality ?? "")")
                                            .foregroundStyle(.gray)
                                    }
                                }
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
    }

    func formatDistance(distance: CLLocationDistance) -> String {
        let steps = distance / (viewModel.stepLength ?? 1)
        if steps != 0 && showSteps {
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 0
            formatter.numberStyle = .decimal
            let number = NSNumber(value: steps)
            return formatter.string(from: number)! + " steps"
        }
        let distanceFormatter = MKDistanceFormatter()
        return distanceFormatter.string(fromDistance: distance)
    }

    func findDirections() {
        let directionsRequest = MKDirections.Request()
        directionsRequest.source = MKMapItem.forCurrentLocation()
        directionsRequest.destination = location
        directionsRequest.transportType = .walking
        directionsRequest.requestsAlternateRoutes = false
        directionsRequest.departureDate = .now

        let searchDirections = MKDirections(request: directionsRequest)
        searchDirections.calculate { (response, error) in
            guard let response = response else {
                print("Error while searching for directions: \(error?.localizedDescription ?? "")")
                return
            }
            self.localDirections = response.routes
            self.distance = response.routes.first?.distance
            
            // Clear existing route and set this as only destination
            viewModel.clearRoute()
            viewModel.addWaypoint(location)
            viewModel.routeLegs = response.routes
        }
    }
}
