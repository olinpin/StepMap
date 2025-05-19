//
//  ViewModel.swift
//  StepMap
//
//  Created by Oliver Hnát on 23.11.2024.
//

import Foundation
import MapKit

class ViewModel: ObservableObject {
    @Published var test: String = UserDefaults.standard.string(forKey: "test") ?? ""
    @Published var directions: [MKRoute] = []
    @Published var stepLength: Double?
    @Published var destination: MKMapItem?
    @Published var showDetails = false


    func saveValue(_ value: String) {
        UserDefaults.standard.set(value, forKey: "test")
        test = value
    }
}
