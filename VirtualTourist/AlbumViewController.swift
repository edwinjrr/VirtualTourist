//
//  AlbumViewController.swift
//  VirtualTourist
//
//  Created by Edwin Rodriguez on 5/23/15.
//  Copyright (c) 2015 Edwin Rodriguez. All rights reserved.
//

import UIKit
import MapKit

class AlbumViewController: UIViewController, MKMapViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var coordinates: CLLocationCoordinate2D!
    
    var photos: [Photo] = [Photo]()
    
    var selectedIndexes = [NSIndexPath]()
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var deleteButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Insert the selected pin in the map view.
        setupMapView()
        
        //Download the images to populate the collectio view.
        //downloadImages(coordinates.latitude, longitude: coordinates.longitude)
    }
    
    // Layout the collection view
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Lay out the collection view so that cells take up 1/3 of the width,
        // with no space in between.
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 2
        layout.minimumInteritemSpacing = 0
        
        let width = floor((self.collectionView.frame.size.width/3) - 2)
        layout.itemSize = CGSize(width: width, height: width)
        collectionView.collectionViewLayout = layout
    }
    
    @IBAction func downloadNewCollection(sender: AnyObject) {
        downloadImages(coordinates.latitude, longitude: coordinates.longitude)
    }
    
    func setupMapView() {
        let regionRadius: CLLocationDistance = 20000
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinates, regionRadius, regionRadius)
        self.mapView.setRegion(coordinateRegion, animated: true)
        var pinAnnotation = MKPointAnnotation()
        pinAnnotation.coordinate = coordinates
        self.mapView.addAnnotation(pinAnnotation)
    }
    
    
    func downloadImages(latitude: Double, longitude: Double) {
        
        let methodArguments = [
            "method": "flickr.photos.search",
            "api_key": "c9c5e79fe507f54c1e3a475194a43da6",
            "bbox": createBoundingBoxString(latitude, longitude: longitude),
            "safe_search": "1",
            "extras": "url_m",
            "format": "json",
            "nojsoncallback": "1"
        ]
        
        Flickr.sharedInstance().getImageFromFlickrBySearch(methodArguments) {(results, error) in
            
            if error == nil {
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.photos = results!
                    self.collectionView.reloadData()
                })
            }
        }
    }
    
    func createBoundingBoxString(latitude: Double, longitude: Double) -> String {
        
        let BOUNDING_BOX_HALF_WIDTH = 1.0
        let BOUNDING_BOX_HALF_HEIGHT = 1.0
        let LAT_MIN = -90.0
        let LAT_MAX = 90.0
        let LON_MIN = -180.0
        let LON_MAX = 180.0
        
        /* Fix added to ensure box is bounded by minimum and maximums */
        let bottom_left_lon = max(longitude - BOUNDING_BOX_HALF_WIDTH, LON_MIN)
        let bottom_left_lat = max(latitude - BOUNDING_BOX_HALF_HEIGHT, LAT_MIN)
        let top_right_lon = min(longitude + BOUNDING_BOX_HALF_HEIGHT, LON_MAX)
        let top_right_lat = min(latitude + BOUNDING_BOX_HALF_HEIGHT, LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoViewCell", forIndexPath: indexPath) as! PhotoCell
        
        //cell.backgroundColor = UIColor.blackColor()
        cell.loadingIndicator.startAnimating()
        cell.imageView.image = nil
        
        let queue:dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
        dispatch_async(queue, { () -> Void in
            var error:NSError?
            
            let photo = self.photos[indexPath.item]
            
            let imageURL = NSURL(string: photo.imageURL)

            if error == nil{
                
                if let imageData = NSData(contentsOfURL: imageURL!) {
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        cell.imageView.image = UIImage(data: imageData)
                        cell.loadingIndicator.stopAnimating()
                        
                        return
                    })
                }
            }
        })
        
        return cell
    }
    
    func configureCell(cell: PhotoCell, atIndexPath indexPath: NSIndexPath) {
        
        // If the cell is "selected" it's color panel is grayed out
        // we use the Swift `find` function to see if the indexPath is in the array
        
        if let index = find(selectedIndexes, indexPath) {
            cell.imageView.alpha = 0.25
        } else {
            cell.imageView.alpha = 1.0
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
        
        // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
        if let index = find(selectedIndexes, indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            selectedIndexes.append(indexPath)
        }
        
        // Then reconfigure the cell
        configureCell(cell, atIndexPath: indexPath)
        
        // And update the buttom button
        updateDeleteButton()
    }
    
    func updateDeleteButton() {
        if selectedIndexes.count > 0 {
            deleteButton.enabled = true
        }
        else {
            deleteButton.enabled = false
        }
    }
}


