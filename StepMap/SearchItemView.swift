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
                        .foregroundStyle(.green)
                    //            Spacer()
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
        .onAppear {
            findDirections()
        }
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

    struct Defaults {
        static let pointOfInterestIcons: [MKPointOfInterestCategory: String] = [
            .museum: "building.columns.fill",
            .musicVenue: "music.note.house.fill",
            .theater: "theatermasks.fill",
            .library: "books.vertical.fill",
            .planetarium: "sparkles",
            .school: "graduationcap.fill",
            .university: "building.columns.fill",
            .movieTheater: "film.fill",
            .nightlife: "music.mic",
            .fireStation: "flame.fill",
            .hospital: "cross.case.fill",
            .pharmacy: "cross.fill",
            .police: "shield.fill",
            .castle: "building.fill",
            .fortress: "shield.lefthalf.filled",
            .landmark: "building.columns.fill",
            .nationalMonument: "star.circle.fill",
            .bakery: "takeoutbag.and.cup.and.straw",
            .brewery: "mug.fill",
            .cafe: "cup.and.saucer.fill",
            .distillery: "wineglass.fill",
            .foodMarket: "cart.fill",
            .restaurant: "fork.knife",
            .winery: "wineglass",
            .animalService: "pawprint.fill",
            .atm: "creditcard.fill",
            .automotiveRepair: "wrench.and.screwdriver.fill",
            .bank: "building.columns.fill",
            .beauty: "scissors",
            .evCharger: "bolt.car.fill",
            .fitnessCenter: "dumbbell.fill",
            .laundry: "washer.fill",
            .mailbox: "envelope.fill",
            .postOffice: "envelope.fill",
            .restroom: "figure.restroom",
            .spa: "drop.fill",
            .store: "bag.fill",
            .amusementPark: "ferriswheel",
            .aquarium: "tortoise.fill",
            .beach: "beach.umbrella.fill",
            .campground: "tent.fill",
            .fairground: "carousel.fill",
            .marina: "sailboat.fill",
            .nationalPark: "leaf.fill",
            .park: "tree.fill",
            .rvPark: "car.fill",
            .zoo: "pawprint.fill",
            .baseball: "baseball.fill",
            .basketball: "basketball.fill",
            .bowling: "figure.bowling",
            .goKart: "car.circle.fill",
            .golf: "flag.and.hole.fill",
            .hiking: "figure.hiking",
            .miniGolf: "flag.and.hole.fill",
            .rockClimbing: "figure.climbing",
            .skatePark: "figure.skating",
            .skating: "figure.skating",
            .skiing: "figure.skiing.downhill",
            .soccer: "soccerball",
            .stadium: "sportscourt.fill",
            .tennis: "tennisball.fill",
            .volleyball: "volleyball.fill",
            .airport: "airplane",
            .carRental: "car.fill",
            .conventionCenter: "building.2.fill",
            .gasStation: "fuelpump.fill",
            .hotel: "bed.double.fill",
            .parking: "parkingsign.circle.fill",
            .publicTransport: "bus.fill",
            .fishing: "fish.fill",
            .kayaking: "figure.rowing",
            .surfing: "figure.surfing",
            .swimming: "figure.pool.swim",
        ]

        static func getIconFor(pointOfInterest: MKPointOfInterestCategory?) -> String {
            if pointOfInterest == nil {
                return "mappin"
            }
            return pointOfInterestIcons[pointOfInterest!] ?? "mappin"
        }
    }

    //    let address = location.placemark.title
}
