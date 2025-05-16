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
    var viewModel: ViewModel
    var directions: [MKRoute] = []
    var destination: MKMapItem?
    let mapView : MKMapView = {
        let map = MKMapView()
        map.showsUserTrackingButton = true
        map.showsUserLocation = true
        return map
    }()
    
    
    init(locationManager: LocationManager, viewModel: ViewModel) {
        self.locationManager = locationManager
        self.viewModel = viewModel
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
    
    override func viewDidAppear(_ animated: Bool) {
        setSearchView()
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
    
    private func setSearchView() {
        let searchViewConctroller = UIHostingController(rootView: SearchView(locationManager: locationManager, viewModel: viewModel))
        searchViewConctroller.view.backgroundColor = .clear
        searchViewConctroller.modalPresentationStyle = .pageSheet
        searchViewConctroller.edgesForExtendedLayout = [.top, .bottom, .left, .right]
        if let sheet = searchViewConctroller.sheetPresentationController {
            let smallDetentId = UISheetPresentationController.Detent.Identifier("small")
            let smallDetent = UISheetPresentationController.Detent.custom(identifier: smallDetentId) { context in
                return 200
            }
            sheet.detents = [smallDetent, .large()]
            sheet.largestUndimmedDetentIdentifier = .large
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.prefersGrabberVisible = true
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
        }
        self.present(searchViewConctroller, animated: true, completion: nil)
    }
    
}

struct MapView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIKitMapView
    @StateObject var locationManager: LocationManager
    @ObservedObject var viewModel: ViewModel

    func makeUIViewController(context: Context) -> UIKitMapView {
        return UIKitMapView(locationManager: locationManager, viewModel: viewModel)
    }
    
    func updateUIViewController(_ uiViewController: UIKitMapView, context: Context) {
        // pass
    }
    
}
