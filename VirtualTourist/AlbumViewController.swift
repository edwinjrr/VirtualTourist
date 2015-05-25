//
//  AlbumViewController.swift
//  VirtualTourist
//
//  Created by Edwin Rodriguez on 5/23/15.
//  Copyright (c) 2015 Edwin Rodriguez. All rights reserved.
//

import UIKit
import MapKit

class AlbumViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var coordinates: CLLocationCoordinate2D!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let regionRadius: CLLocationDistance = 20000
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinates, regionRadius, regionRadius)
        self.mapView.setRegion(coordinateRegion, animated: true)
        var pinAnnotation = MKPointAnnotation()
        pinAnnotation.coordinate = coordinates
        self.mapView.addAnnotation(pinAnnotation)

    }

    

}
