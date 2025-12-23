//
//  Utils.swift
//  StepMap
//
//  Created by Oliver Hnát on 27.11.2024.
//

import Foundation
import MapKit
import SwiftUI

// MARK: - Formatters
struct Formatters {
    /// Formats seconds into "X min" or "X hr Y min"
    static func formatWalkingTime(_ seconds: TimeInterval) -> String {
        if seconds < 60 { return "< 1 min" }
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return minutes > 0 ? "\(hours) hr \(minutes) min" : "\(hours) hr"
        }
        return "\(minutes) min"
    }
    
    /// Formats time in compact form: "5m" or "1h 30m"
    static func formatTimeCompact(_ seconds: TimeInterval) -> String {
        if seconds < 60 { return "<1m" }
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    /// Formats distance in meters to km or m
    static func formatDistance(_ meters: CLLocationDistance) -> String {
        if meters >= 1000 {
            return String(format: "%.1f km", meters / 1000)
        }
        return String(format: "%.0f m", meters)
    }
    
    /// Formats number with thousands separator
    static func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    /// Formats steps with "steps" suffix
    static func formatSteps(_ steps: Int) -> String {
        return formatNumber(steps) + " steps"
    }
    
    /// Estimates steps from distance using step length
    static func estimateSteps(distance: CLLocationDistance, stepLength: Double?) -> Int? {
        guard let stepLength = stepLength, stepLength > 0 else { return nil }
        return Int(distance / stepLength)
    }
    
    /// Formats step length in centimeters
    static func formatStepLength(_ meters: Double?) -> String {
        guard let meters = meters else { return "--" }
        let cm = meters * 100
        return String(format: "%.1f cm", cm)
    }
    
    /// Formats walking speed in km/h
    static func formatWalkingSpeed(_ metersPerSecond: Double?) -> String {
        guard let mps = metersPerSecond else { return "--" }
        let kmh = mps * 3.6
        return String(format: "%.1f km/h", kmh)
    }
}

// MARK: - Defaults
struct Defaults {
    static let routeColor: [UIColor] = [
        .blue,
//        .red,
//        .yellow,
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
    
    /// Returns colors that match Apple Maps style more closely
    static func getAppleStyleColorFor(pointOfInterest: MKPointOfInterestCategory?) -> Color {
        guard let poi = pointOfInterest else { return .red }
        
        // Apple Maps style color groups
        switch poi {
        // Food & Drink - Orange
        case .restaurant, .bakery, .foodMarket:
            return Color(red: 1.0, green: 0.58, blue: 0.0) // Apple Orange
        case .cafe:
            return Color(red: 0.6, green: 0.4, blue: 0.2) // Brown
        case .brewery, .winery, .distillery:
            return Color(red: 0.6, green: 0.2, blue: 0.4) // Wine/Purple-ish
            
        // Entertainment - Purple
        case .nightlife, .theater, .movieTheater, .musicVenue:
            return Color(red: 0.69, green: 0.32, blue: 0.87) // Purple
            
        // Parks & Nature - Green
        case .park, .nationalPark, .campground, .beach, .zoo, .aquarium:
            return Color(red: 0.2, green: 0.78, blue: 0.35) // Apple Green
            
        // Sports & Fitness - Orange/Green
        case .fitnessCenter, .golf, .tennis, .basketball, .baseball, .soccer, .stadium, .hiking, .swimming, .skiing:
            return Color(red: 1.0, green: 0.58, blue: 0.0) // Orange
            
        // Education & Culture - Brown/Orange
        case .museum, .library, .school, .university:
            return Color(red: 0.6, green: 0.4, blue: 0.2) // Brown
            
        // Landmarks & Historical - Brown
        case .landmark, .castle, .fortress, .nationalMonument:
            return Color(red: 0.6, green: 0.4, blue: 0.2) // Brown
            
        // Healthcare - Red
        case .hospital, .pharmacy:
            return Color(red: 1.0, green: 0.23, blue: 0.19) // Apple Red
            
        // Emergency Services - Blue
        case .police, .fireStation:
            return Color(red: 0.0, green: 0.48, blue: 1.0) // Apple Blue
            
        // Transit & Travel - Blue
        case .airport, .publicTransport, .parking, .gasStation, .evCharger, .carRental:
            return Color(red: 0.0, green: 0.48, blue: 1.0) // Apple Blue
            
        // Hotels & Lodging - Purple
        case .hotel:
            return Color(red: 0.69, green: 0.32, blue: 0.87) // Purple
            
        // Shopping & Services - Blue
        case .store, .bank, .atm, .postOffice, .mailbox, .laundry:
            return Color(red: 0.0, green: 0.48, blue: 1.0) // Apple Blue
            
        // Beauty & Personal Care - Pink
        case .beauty, .spa:
            return Color(red: 1.0, green: 0.18, blue: 0.33) // Pink
            
        // Automotive - Gray
        case .automotiveRepair:
            return Color(red: 0.56, green: 0.56, blue: 0.58) // Gray
            
        // Animal Services - Green
        case .animalService:
            return Color(red: 0.2, green: 0.78, blue: 0.35) // Green
            
        // Amusement - Orange
        case .amusementPark, .fairground:
            return Color(red: 1.0, green: 0.58, blue: 0.0) // Orange
            
        // Water Activities - Teal/Blue
        case .marina, .fishing, .kayaking, .surfing:
            return Color(red: 0.35, green: 0.78, blue: 0.98) // Teal
            
        // Default
        default:
            return Color(red: 1.0, green: 0.23, blue: 0.19) // Red
        }
    }
}
