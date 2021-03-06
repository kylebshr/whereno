//
//  ViewController.swift
//  Whereno
//
//  Created by Kyle Bashour on 4/24/16.
//  Copyright © 2016 Kyle Bashour. All rights reserved.
//

import UIKit
import RealmSwift
import RealmMapView
import Async
import CoreLocation

class MapViewController: UIViewController {


    // MARK: Outlets

    @IBOutlet var mapView: RealmMapView!
    @IBOutlet weak var addLocationButton: UIBarButtonItem!

    // MARK: Properties

    let geocoder = CLGeocoder()
    let annotationViewReuseId = "AnnotationViewReuseId"
    let realm = try! Realm()
    let titleView = R.nib.mapTitleView.firstView(owner: nil)!
    let locationCellHeight = 124

    var didShowInitialLocation = false


    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = titleView
        titleView.title = "Locating..."
        titleView.tintColor = .whiteColor()

        // Zooms into random cluster unless we set to false
        mapView.zoomOnFirstRefresh = false
    }


    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        // If we're not logged in, present the login!
        if User.authenticatedUser == nil {
            presentViewController(R.storyboard.login.loginViewController()!, animated: true, completion: nil)
        }

        // Make sure we load any locations that have been added to realm
        mapView.refreshMapView()
    }

    // MARK: IBActions

    // Centers and zooms the map to your current location
    @IBAction func locationButtonTapped(sender: UIBarButtonItem) {
        updateMapRegion(mapView.userLocation.coordinate)
    }

    // Present the creation UI
    @IBAction func addLocationButtonTapped(sender: UIBarButtonItem) {

        guard CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse else {

            let alert = UIAlertController(
                title: "We Need Your Location!",
                message: "To post new hammock locations, we need permission to get your current location.",
                preferredStyle: .Alert
            )

            let settings = UIAlertAction(title: "Take Me To Settings", style: .Default) { (alertAction) in
                if let appSettings = NSURL(string: UIApplicationOpenSettingsURLString) {
                    UIApplication.sharedApplication().openURL(appSettings)
                }
            }

            let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)

            alert.addAction(settings)
            alert.addAction(cancel)
                
            presentViewController(alert, animated: true, completion: nil)

            return
        }

        let nav = R.storyboard.compose.initialViewController()!
        presentViewController(nav, animated: true, completion: nil)
    }


    // MARK: Helpers

    // Create a region from coordinates and animate to that region
    func updateMapRegion(coordinate: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015))
        mapView.setRegion(region, animated: true)
    }

    // Reverse geocode the user location for the nav bar title
    func updateLocationTitle(location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in

            // Placemarks and UI updates should be worked with on main thread
            Async.main {
                guard let locality = placemarks?.first?.locality else {
                    self?.titleView.title = "Current Location"
                    return
                }

                self?.titleView.title = locality
            }
        }
    }


    /* 
     Due to the nature of using RealmMapView and not my own implementation, I have to
     query my HammockLocations to find the underlying object behind an annotation.
    */
    func hammockLocationsForAnnotationView(view: MKAnnotationView) -> [HammockLocation]? {

        guard let annotation = view.annotation as? ABFAnnotation else {
            return nil
        }

        let locations = annotation.safeObjects.flatMap { (object) -> HammockLocation? in
            let latitude = object.coordinate.latitude
            let longitude = object.coordinate.longitude
            let filter = "latitude == \(latitude) AND longitude == \(longitude) AND title == '\(object.title)'"
            return realm.objects(HammockLocation).filter(filter).first
        }

        return locations.count > 0 ? locations : nil
    }

    func getLocationsForCurrentRegion() {

        titleView.showSubTitleWithText("Updating")

        // Perform the fetch call, then simply refresh (the objects are added to realm)
        ObjectFetcher.sharedInstance.getLocationsForRegion(mapView.region) { [weak self] _ in
            self?.mapView.refreshMapView()
            self?.titleView.hideSubTitle()
        }
    }
}

extension MapViewController: MKMapViewDelegate {

    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {

        // If we have a location, update the title to show the users city
        if let location = userLocation.location {
            updateLocationTitle(location)
        }

        // If it's the first time we found them, zoom into their location
        if !didShowInitialLocation {
            updateMapRegion(userLocation.coordinate)
            didShowInitialLocation = true
        }
    }

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {

        guard let annotation = annotation as? ABFAnnotation else {
            return nil
        }

        if let annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(annotationViewReuseId) as? ABFClusterAnnotationView {

            annotationView.annotation = annotation
            annotationView.count = UInt(annotation.safeObjects.count)

            return annotationView
        }
        else {

            let annotationView = ABFClusterAnnotationView(annotation: annotation, reuseIdentifier: annotationViewReuseId)

            // Configure the view with the annotation info
            annotationView.canShowCallout = true
            annotationView.count = UInt(annotation.safeObjects.count)
            annotationView.annotation = annotation
            annotationView.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
            annotationView.color = .darkerGreen()

            // Register for 3D Touch
            registerForPreviewingWithDelegate(self, sourceView: annotationView)

            return annotationView
        }
    }

    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {

        // Make sure there's an underlying HammockLocation(s), otherwise we do nothing
        guard let locations = hammockLocationsForAnnotationView(view) where locations.count > 0 else {
            return
        }

        // Push either a detail view or list view
        if locations.count == 1 {
            let vc = R.storyboard.map.locationDetailViewController()!
            vc.location = locations.first
            navigationController?.pushViewController(vc, animated: true)
        }
        else {
            let vc = R.storyboard.map.locationListViewController()!
            vc.locations = locations
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        getLocationsForCurrentRegion()
    }
}

extension MapViewController: UIViewControllerPreviewingDelegate {

    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {

        // We only respond if the sourceView is an annotation view, and has underlying HammockLocations
        if let tappedView = previewingContext.sourceView as? ABFClusterAnnotationView, locations = hammockLocationsForAnnotationView(tappedView) {


            // Look for a popover, and include it in the rect if it exists
            var popover: UIView?
            for view in tappedView.subviews {
                for view in view.subviews {
                    for view in view.subviews {
                        popover = view
                    }
                }
            }

            // Add the popover to the 3D Touch rect
            if let popover = popover, frame = popover.superview?.convertRect(popover.frame, toView: tappedView) {
                previewingContext.sourceRect = CGRect(
                    x: frame.origin.x,
                    y: frame.origin.y,
                    width: frame.width,
                    height: frame.height + tappedView.frame.height
                )
            }

            // Return either a detail or list view
            if locations.count == 1 {
                let vc = R.storyboard.map.locationDetailViewController()!

                // We don't want this at the bottom of the screen during a preview
                vc.shouldShowTextInputView = false

                vc.location = locations.first
                return vc
            }
            else {
                let vc = R.storyboard.map.locationListViewController()!

                // Set a nice preferred content size to only be as tall as needed, minus the white space and separator
                let size = CGSize(width: view.frame.width, height: min(CGFloat(locations.count * locationCellHeight) - 5, mapView.frame.height - (navigationController?.navigationBar.frame.height ?? 0) * 2))
                vc.preferredContentSize = size

                vc.locations = locations
                return vc
            }
        }

        return nil
    }

    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {

        // If we were previewing a detail view, we have to set this back to true!
        if let vc = viewControllerToCommit as? LocationDetailViewController {
            vc.shouldShowTextInputView = true
        }

        navigationController?.pushViewController(viewControllerToCommit, animated: true)
    }
}
