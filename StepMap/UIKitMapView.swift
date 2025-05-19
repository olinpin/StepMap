//
//  UIKitMapView.swift
//  StepMap
//
//  Created by Oliver Hnat on 13/05/2025.
//

import UIKit
import MapKit
import SwiftUI
import Combine

class UIKitMapView: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    var locationManager: LocationManager
    var viewModel: ViewModel
    var oldDirections: [MKRoute] = []
    var oldDestination: MKMapItemAnnotation?
    private var cancellables = Set<AnyCancellable>()
    let searchViewConctroller: UIHostingController<SearchView>
    var annotationViewController: UIHostingController<AnnotationView>?
    let mapView : MKMapView = {
        let map = MKMapView()
        map.showsUserTrackingButton = true
        map.showsUserLocation = true
        map.selectableMapFeatures = .pointsOfInterest
        map.pitchButtonVisibility = .adaptive
        return map
    }()
    
    
    init(locationManager: LocationManager, viewModel: ViewModel) {
        self.locationManager = locationManager
        self.viewModel = viewModel
        self.searchViewConctroller = UIHostingController(rootView: SearchView(locationManager: locationManager, viewModel: viewModel))
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
        
        mapView.delegate = self
        setMapConstraints()
        setLocation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        showSearchView()
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
    
    private func showSearchView() {
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
    
    private func refreshRoute() {
        DispatchQueue.main.async {
            for route in self.oldDirections {
                self.mapView.removeOverlay(route.polyline)
            }
            self.oldDirections = self.viewModel.directions
            for route in self.viewModel.directions {
                self.mapView.addOverlay(route.polyline, level: .aboveRoads)
            }
            
            if let destination = self.oldDestination {
                self.mapView.removeAnnotation(destination)
            }
            if let destination = self.viewModel.destination {
                self.oldDestination = MKMapItemAnnotation(mapItem: destination)
                self.mapView.addAnnotation(self.oldDestination!)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: any MKOverlay) -> MKOverlayRenderer {
        let renderer = MKGradientPolylineRenderer(overlay: overlay)
        renderer.setColors(Defaults.routeColor, locations: [])
        renderer.lineCap = .round
        renderer.lineWidth = Defaults.routeWidth
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, didSelect annotation: any MKAnnotation) {
        hideSearchView()
        hideAnnotationView()
        showAnnotation(annotation: annotation)
    }
    
    func showAnnotation(annotation: MKAnnotation) {
        viewModel.showDetails = true
        let location = CLLocation(latitude: annotation.coordinate.latitude,
                                  longitude: annotation.coordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first, error == nil else { return }
            
            self.annotationViewController = UIHostingController(rootView: AnnotationView(pm: placemark, title: annotation.title as? String, coordinate: location, viewModel: self.viewModel))
            if let avc = self.annotationViewController {
                avc.view.backgroundColor = .clear
                avc.modalPresentationStyle = .pageSheet
                avc.edgesForExtendedLayout = [.top, .bottom, .left, .right]
                if let sheet = avc.sheetPresentationController {
                    let smallDetentId = UISheetPresentationController.Detent.Identifier("small")
                    let smallDetent = UISheetPresentationController.Detent.custom(identifier: smallDetentId) { context in
                        return 350
                    }
                    sheet.detents = [smallDetent, .large()]
                    sheet.largestUndimmedDetentIdentifier = .large
                    sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                    sheet.prefersGrabberVisible = true
                    sheet.prefersEdgeAttachedInCompactHeight = true
                    sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
                }
                self.present(avc, animated: true, completion: nil)
            }
        }

    }
    
    func mapView(_ mapView: MKMapView, didDeselect annotation: any MKAnnotation) {
        if viewModel.showDetails {
            viewModel.showDetails = false
        }
    }
    
    func hideSearchView() {
        searchViewConctroller.dismiss(animated: true)
    }
    func hideAnnotationView() {
        if let avc = self.annotationViewController {
            avc.dismiss(animated: true)
        }
    }
    
    private func bindViewModel() {
        viewModel.$directions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshRoute()
            }
            .store(in: &cancellables)
        viewModel.$showDetails
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                print(value)
                if !value {
                    self?.hideAnnotationView()
                    self?.showSearchView()
//                    self?.mapView.selectedAnnotations = []
                }
            }
            .store(in: &cancellables)
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
