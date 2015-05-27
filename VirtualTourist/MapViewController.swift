//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Edwin Rodriguez on 5/22/15.
//  Copyright (c) 2015 Edwin Rodriguez. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!

    var longTapRecognizer: UILongPressGestureRecognizer!
    
    var annotations = [MKPointAnnotation]()
    
    var session: NSURLSession!
    
    var photos: [Photo] = [Photo]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        restoreMapRegion(false)
        
        longTapRecognizer = UILongPressGestureRecognizer(target: self, action: "handleLongTap:")
    }
    
    override func viewWillAppear(animated: Bool) {
        self.view.addGestureRecognizer(longTapRecognizer!)
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.view.removeGestureRecognizer(longTapRecognizer!)
    }
    
    // MARK: - Long Tap Recognizer
    
    func handleLongTap(sender: UILongPressGestureRecognizer) {
        
        if (sender.state == UIGestureRecognizerState.Began) {

            //Get the location of the gesture
            let tapLocation: CGPoint = sender.locationInView(self.mapView)

            //Convert the location of the gesture to coordinates
            let tapLocationCoordinates = self.mapView.convertPoint(tapLocation, toCoordinateFromView: self.mapView)
            
            //Get an address from coordinates (Reverse geocoding)
            var geocoder = CLGeocoder()
            
            //Get the CLLocation for the reverse geocoding
            var longitude: CLLocationDegrees = tapLocationCoordinates.longitude
            var latitude: CLLocationDegrees = tapLocationCoordinates.latitude
            var location = CLLocation(latitude: latitude, longitude: longitude)
            
            var pinAnnotation = MKPointAnnotation()
            pinAnnotation.coordinate = tapLocationCoordinates
            
            self.annotations.append(pinAnnotation)
            self.mapView.addAnnotation(pinAnnotation)
        }
    }

    // MARK: - Save the zoom level helpers
    
    // Property for the file path.
    
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        return url.URLByAppendingPathComponent("mapRegionArchive").path!
    }
    
    func saveMapRegion() {
        
        // Place the "center" and "span" of the map into a dictionary
        // The "span" is the width and height of the map in degrees.
        // It represents the zoom level of the map.
        
        let dictionary = [
            "latitude" : mapView.region.center.latitude,
            "longitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta
        ]
        
        // Archive the dictionary into the filePath
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
    }
    
    func restoreMapRegion(animated: Bool) {
        
        // if we can unarchive a dictionary, we will use it to set the map back to its previous center and span
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            
            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            let latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            
            mapView.setRegion(savedRegion, animated: animated)
        }
    }
    
    // This allows the view controller to be notified whenever the map region changes and save the new region.
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    
    // Here we set the pin to be draggable and have an animation of dropping into the map after been dropped.
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        let reuseId = "pin"
    
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView!

        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        pinView!.animatesDrop = true
        //pinView!.draggable = true
        //pinView!.rightCalloutAccessoryView = UIButton.buttonWithType(.DetailDisclosure) as! UIButton
        //pinView!.canShowCallout = true
        //pinView!.selected = true
        
        return pinView
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        
        let controller = storyboard!.instantiateViewControllerWithIdentifier("AlbumViewController") as! AlbumViewController

        controller.coordinates = view.annotation.coordinate
        controller.photos = self.photos

        self.navigationController!.pushViewController(controller, animated: true)
    }
    
    //Action for the annotation callout accesory.
    //TODO: Use Pin object to change properties of it (title and subtitle)
    //Update de pin coordinates when the drag ends.
    //Keeps all the pins selected so they can be always draggable
    //func mapView(mapView: MKMapView!, didDeselectAnnotationView view: MKAnnotationView!) {
    //    view.selected = true
    //}
    
    //            geocoder.reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
    //
    //                if error != nil {
    //                    println("Reverse geocoder failed with error" + error.localizedDescription)
    //                    return
    //                }
    //                else {
    //                    if placemarks.count > 0 {
    //                        let placemark = placemarks[0] as! CLPlacemark
    //
    //                        var locality = placemark.locality
    //                        var administrativeArea = placemark.administrativeArea
    //                        var country = placemark.country
    //                    }
    //                    else {
    //                        println("Problem with the data received from geocoder")
    //                    }
    //                }
    //            })
}

