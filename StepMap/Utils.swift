//
//  Utils.swift
//  StepMap
//
//  Created by Oliver Hnát on 27.11.2024.
//

import Foundation
import MapKit
import SwiftUI

struct Defaults {
    static let routeColor: [Color] = [
        .blue,
        .red,
        .yellow,
    ]
    static let routeWidth: CGFloat = 8

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

    static let pointOfInterestColors: [MKPointOfInterestCategory: Color] = [
        // Cultural & Educational
        .museum: .blue,
        .musicVenue: .purple,
        .theater: .purple,
        .library: .blue,
        .planetarium: .teal,
        .school: .orange,
        .university: .orange,

        // Entertainment
        .movieTheater: .red,
        .nightlife: .pink,

        // Emergency & Services
        .fireStation: .red,
        .hospital: .red,
        .pharmacy: .green,
        .police: .blue,

        // Historical & Landmarks
        .castle: .brown,
        .fortress: .brown,
        .landmark: .yellow,
        .nationalMonument: Color(red: 252, green: 194, blue: 0),

        // Food & Drink
        .bakery: .yellow,
        .brewery: .brown,
        .cafe: .brown,
        .distillery: .brown,
        .foodMarket: .green,
        .restaurant: .orange,
        .winery: .purple,

        // Commercial & Services
        .animalService: .green,
        .atm: .green,
        .automotiveRepair: .gray,
        .bank: .green,
        .beauty: .pink,
        .evCharger: .green,
        .fitnessCenter: .purple,
        .laundry: .blue,
        .mailbox: .blue,
        .postOffice: .blue,
        .restroom: .gray,
        .spa: .teal,
        .store: .yellow,

        // Nature & Recreation
        .amusementPark: .yellow,
        .aquarium: .teal,
        .beach: .yellow,
        .campground: .green,
        .fairground: .yellow,
        .marina: .blue,
        .nationalPark: .green,
        .park: .green,
        .rvPark: .green,
        .zoo: .green,

        // Sports & Activities
        .baseball: .red,
        .basketball: .orange,
        .bowling: .purple,
        .goKart: .red,
        .golf: .green,
        .hiking: .green,
        .miniGolf: .green,
        .rockClimbing: .gray,
        .skatePark: .gray,
        .skating: .gray,
        .skiing: .blue,
        .soccer: .green,
        .stadium: .blue,
        .tennis: .green,
        .volleyball: .yellow,

        // Transportation
        .airport: .blue,
        .carRental: .gray,
        .conventionCenter: .blue,
        .gasStation: .yellow,
        .hotel: .purple,
        .parking: .gray,
        .publicTransport: .blue,

        // Outdoor Activities
        .fishing: .blue,
        .kayaking: .blue,
        .surfing: .blue,
        .swimming: .blue,
    ]

    static func getIconFor(pointOfInterest: MKPointOfInterestCategory?) -> String {
        if pointOfInterest == nil {
            return "mappin"
        }
        return pointOfInterestIcons[pointOfInterest!] ?? "mappin"
    }

    static func getColorFor(pointOfInterest: MKPointOfInterestCategory?) -> Color {
        if pointOfInterest == nil {
            return .red
        }
        return pointOfInterestColors[pointOfInterest!] ?? .red
    }
}
