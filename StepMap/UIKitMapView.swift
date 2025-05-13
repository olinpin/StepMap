//
//  UIKitMapView.swift
//  StepMap
//
//  Created by Oliver Hnat on 13/05/2025.
//

import UIKit
import MapKit
import SwiftUI

class UIKitMapView: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    var locationManager: LocationManager
    let mapView : MKMapView = {
        let map = MKMapView()
        map.showsUserTrackingButton = true
        map.showsUserLocation = true
        return map
    }()
    
    init(locationManager: LocationManager) {
        self.locationManager = locationManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        setMapConstraints()
        setLocation()
    }
    
    private func setLocation() {
        locationManager.requestAuthorization()
        locationManager.requestLocation()
        if let userLocation = locationManager.location {
            let viewRegion = MKCoordinateRegion(center: userLocation, latitudinalMeters: 2000, longitudinalMeters: 2000)
            mapView.setRegion(viewRegion, animated: true)
        }
        mapView.setUserTrackingMode(.follow, animated: true)
    }
    
    private func setMapConstraints() {
        view.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        mapView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        mapView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
    }
    
}

struct MapView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIKitMapView
    @StateObject var locationManager: LocationManager

    func makeUIViewController(context: Context) -> UIKitMapView {
        return UIKitMapView(locationManager: locationManager)
    }
    
    func updateUIViewController(_ uiViewController: UIKitMapView, context: Context) {
        // pass
    }
    
}
