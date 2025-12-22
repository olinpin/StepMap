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
    var waypointAnnotations: [MKPointAnnotation] = []
    private var cancellables = Set<AnyCancellable>()
    let routePlannerViewController: UIHostingController<RoutePlannerView>
    var annotationViewController: UIHostingController<AnnotationView>?
    private var isSelectingNewAnnotation = false  // Flag to prevent route planner showing during annotation switch
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
        self.routePlannerViewController = UIHostingController(rootView: RoutePlannerView(viewModel: viewModel, locationManager: locationManager))
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
        
        // Add long-press gesture for adding waypoints
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPress)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        showRoutePlannerView()
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
    
    private func showRoutePlannerView() {
        routePlannerViewController.view.backgroundColor = .clear
        routePlannerViewController.modalPresentationStyle = .pageSheet
        routePlannerViewController.edgesForExtendedLayout = [.top, .bottom, .left, .right]
        if let sheet = routePlannerViewController.sheetPresentationController {
            let smallDetentId = UISheetPresentationController.Detent.Identifier("small")
            let smallDetent = UISheetPresentationController.Detent.custom(identifier: smallDetentId) { context in
                return 300  // Increased from 200 to 300
            }
            let mediumDetentId = UISheetPresentationController.Detent.Identifier("medium")
            let mediumDetent = UISheetPresentationController.Detent.custom(identifier: mediumDetentId) { context in
                return context.maximumDetentValue * 0.5
            }
            sheet.detents = [smallDetent, mediumDetent, .large()]
            sheet.largestUndimmedDetentIdentifier = .large
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.prefersGrabberVisible = true
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
        }
        self.present(routePlannerViewController, animated: true, completion: nil)
    }
    
    private func refreshRoute() {
        DispatchQueue.main.async {
            // Remove old routes
            for route in self.oldDirections {
                self.mapView.removeOverlay(route.polyline)
            }
            
            // Add new routes
            self.oldDirections = self.viewModel.routeLegs
            for route in self.viewModel.routeLegs {
                self.mapView.addOverlay(route.polyline, level: .aboveRoads)
            }
            
            // Remove old waypoint annotations
            self.mapView.removeAnnotations(self.waypointAnnotations)
            self.waypointAnnotations.removeAll()
            
            // Add new waypoint annotations
            for (index, waypoint) in self.viewModel.waypoints.enumerated() {
                let annotation = MKPointAnnotation()
                annotation.coordinate = waypoint.placemark.coordinate
                annotation.title = waypoint.name
                annotation.subtitle = "Stop \(index + 1)"
                self.waypointAnnotations.append(annotation)
                self.mapView.addAnnotation(annotation)
            }
            
            // Zoom to show entire route
            if !self.viewModel.routeLegs.isEmpty {
                self.zoomToFitRoute()
            }
        }
    }
    
    private func zoomToFitRoute() {
        guard !viewModel.routeLegs.isEmpty else { return }
        
        var mapRect = MKMapRect.null
        for route in viewModel.routeLegs {
            mapRect = mapRect.union(route.polyline.boundingMapRect)
        }
        
        let padding = UIEdgeInsets(top: 50, left: 50, bottom: 300, right: 50)
        mapView.setVisibleMapRect(mapRect, edgePadding: padding, animated: true)
    }
    
    // MARK: - Long Press Gesture Handler
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        
        let point = gesture.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        
        // Reverse geocode to get place info
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self, let placemark = placemarks?.first else { return }
            
            let mkPlacemark = MKPlacemark(placemark: placemark)
            let mapItem = MKMapItem(placemark: mkPlacemark)
            mapItem.name = placemark.name ?? "Dropped Pin"
            
            // Add to waypoints and recalculate
            self.viewModel.addWaypoint(mapItem)
            self.recalculateRoute()
        }
    }
    
    private func recalculateRoute() {
        Task {
            let routes = await RouteService.calculateRoute(
                from: locationManager.location,
                waypoints: viewModel.waypoints
            )
            await MainActor.run {
                viewModel.routeLegs = routes
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
        // Don't show annotation view for waypoint annotations or user location
        if waypointAnnotations.contains(where: { $0 === annotation as AnyObject }) {
            return
        }
        if annotation is MKUserLocation {
            return
        }
        
        // Set flag to prevent route planner from showing during annotation switch
        isSelectingNewAnnotation = true
        
        hideRoutePlannerView()
        hideAnnotationView()
        showAnnotation(annotation: annotation)
    }
    
    func showAnnotation(annotation: MKAnnotation) {
        viewModel.showDetails = true
        let location = CLLocation(latitude: annotation.coordinate.latitude,
                                  longitude: annotation.coordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self, let placemark = placemarks?.first, error == nil else {
                self?.isSelectingNewAnnotation = false
                return
            }
            
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
                self.present(avc, animated: true) {
                    // Clear the flag after presentation is complete
                    self.isSelectingNewAnnotation = false
                }
            } else {
                self.isSelectingNewAnnotation = false
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didDeselect annotation: any MKAnnotation) {
        // Don't trigger route planner if we're selecting a new annotation
        if isSelectingNewAnnotation {
            return
        }
        
        if viewModel.showDetails {
            viewModel.showDetails = false
        }
    }
    
    func deselectAllAnnotations() {
        for annotation in mapView.selectedAnnotations {
            mapView.deselectAnnotation(annotation, animated: true)
        }
    }
    
    func hideRoutePlannerView() {
        routePlannerViewController.dismiss(animated: true)
    }
    
    func hideAnnotationView() {
        if let avc = self.annotationViewController {
            avc.dismiss(animated: true)
        }
    }
    
    private func bindViewModel() {
        viewModel.$routeLegs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshRoute()
            }
            .store(in: &cancellables)
        
        // Watch for waypoints being cleared to deselect annotations
        viewModel.$waypoints
            .receive(on: DispatchQueue.main)
            .sink { [weak self] waypoints in
                if waypoints.isEmpty {
                    self?.deselectAllAnnotations()
                }
            }
            .store(in: &cancellables)
        
        viewModel.$showDetails
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self = self else { return }
                // Don't show route planner if we're in the middle of selecting a new annotation
                if !value && !self.isSelectingNewAnnotation {
                    self.hideAnnotationView()
                    self.showRoutePlannerView()
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
