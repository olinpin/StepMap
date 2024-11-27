//
//  LocationManager.swift
//  StepMap
//
//  Created by Oliver Hnát on 25.11.2024.
//

import CoreLocation
import Foundation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let manager = CLLocationManager()

    @Published var location: CLLocationCoordinate2D?

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestLocation() {
        manager.requestLocation()
    }

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first?.coordinate
    }
}

extension LocationManager {
    func locationManager(
        _ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus
    ) {
        switch status {
        case .notDetermined:
            print("Authorization not determined")
        case .restricted:
            print("Authorization restricted")
        case .denied:
            print("Authorization denied")
        case .authorizedAlways:
            print("Authorization always authorized")
        case .authorizedWhenInUse:
            print("Authorization when in use authorized")
        @unknown default:
            print("Authorization went wrong")
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        print(error)
    }
}
