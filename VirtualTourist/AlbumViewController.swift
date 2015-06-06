//
//  AlbumViewController.swift
//  VirtualTourist
//
//  Created by Edwin Rodriguez on 5/23/15.
//  Copyright (c) 2015 Edwin Rodriguez. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class AlbumViewController: UIViewController, MKMapViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var coordinates: CLLocationCoordinate2D!
    
    var pin: Location!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var newCollection: UIBarButtonItem!
    @IBOutlet weak var noImagesFound: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Insert the selected pin in the map view.
        setupMapView()
    }
    
    override func viewWillAppear(animated: Bool) {
        
        activityIndicator.startAnimating()
        
        //Download the images to populate the collection view.
        if pin.photos.isEmpty {
            downloadPhotos()
        } else {
            activityIndicator.stopAnimating()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        saveContext()
    }
    
    // Layout the collection view
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Lay out the collection view so that cells take up 1/3 of the width, with a small space in between.
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 2
        layout.minimumInteritemSpacing = 0
        
        let width = floor((self.collectionView.frame.size.width/3) - 2)
        layout.itemSize = CGSize(width: width, height: width)
        collectionView.collectionViewLayout = layout
    }
    
    // Download the photos from Flickr
    
    func downloadPhotos() {
        
        let methodArguments = [
            "method": "flickr.photos.search",
            "api_key": "c9c5e79fe507f54c1e3a475194a43da6",
            "lat": String(stringInterpolationSegment: coordinates.latitude),
            "lon": String(stringInterpolationSegment: coordinates.longitude),
            "safe_search": "1",
            "extras": "url_m",
            "format": "json",
            "nojsoncallback": "1",
            "per_page": "21"
        ]
        
        Flickr.sharedInstance().getImageFromFlickrBySearch(methodArguments) {(results, error) in
            
            if let error = error {
                println("Error with the Flickr method.") //<--- Setup an AlertView here!
            }
            else {
                
                if let results = results as [[String : AnyObject]]? {
                    
                    if results.isEmpty {
                        
                        //If the results array is empty, no photos were found and a label will notify the user.
                        // Update view on the main thread
                        dispatch_async(dispatch_get_main_queue()) {
                            self.noImagesFound.hidden = false
                            self.activityIndicator.stopAnimating()
                        }
                    
                    } else {
                        
                        // Parse the array of photos dictionaries
                        var photos = results.map() { (dictionary: [String : AnyObject]) -> Photo in
                            
                            let photo = Photo(dictionary: dictionary, insertIntoMangedObjectContext: self.sharedContext)
                            
                            photo.pin = self.pin
                            
                            return photo
                        }
                        
                        // Update the collection on the main thread
                        dispatch_async(dispatch_get_main_queue()) {
                            self.collectionView.reloadData()
                            self.activityIndicator.stopAnimating()
                        }
                        
                        // Save the context
                        self.saveContext()
                    }
                }
            }
        }
    }
    
    // MARK: - Core Data Convenience
    
    lazy var sharedContext: NSManagedObjectContext =  {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
        }()
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    // MARK: - UICollectionView
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return pin.photos.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let photo = pin.photos[indexPath.item]
        var photoImage = UIImage(named: "placeholder")
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoViewCell", forIndexPath: indexPath) as! PhotoCell
        
        cell.loadingIndicator.startAnimating()
        cell.imageView.image = nil
        
        //Set the photo image
        
        if photo.photoImage != nil {
            photoImage = photo.photoImage
            cell.loadingIndicator.stopAnimating()
        }
        else {
            
            // Start the task that will eventually download the image
            let task = Flickr.sharedInstance().taskForImage(photo.imageURL) { data, error in
                
                if let data = data {
                    // Create the image
                    let image = UIImage(data: data)
                    
                    // update the model, so that the information gets cashed
                    photo.photoImage = image
                    
                    // update the cell later, on the main thread
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.imageView!.image = image
                        cell.loadingIndicator.stopAnimating()
                    }
                }
            }
            
            // This is the custom property on this cell.
            cell.taskToCancelifCellIsReused = task
        }
        
        cell.imageView.image = photoImage
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let photo = pin.photos[indexPath.item]
        
        photo.pin = nil
        
        collectionView.deleteItemsAtIndexPaths([indexPath])
        
        sharedContext.deleteObject(photo)
        
        self.saveContext()
    }
    
    // MARK: - Actions and Helpers
    
    //Show the pin selected in the small map view on top of the view controller.
    func setupMapView() {
        let regionRadius: CLLocationDistance = 20000
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinates, regionRadius, regionRadius)
        self.mapView.setRegion(coordinateRegion, animated: true)
        var pinAnnotation = MKPointAnnotation()
        pinAnnotation.coordinate = coordinates
        self.mapView.addAnnotation(pinAnnotation)
    }
    
//    var currentIndexPaths = [NSIndexPath]()
    
    @IBAction func deleteAllPhotos(sender: AnyObject) {
        
//        let photo = pin.photos[indexPath.item]
//
//        photo.pin = nil
//
//        collectionView.deleteItemsAtIndexPaths([indexPath])
//
//        sharedContext.deleteObject(photo)
//        self.saveContext()
        
//        for photo in pin.photos {
//            photo.pin = nil
//            collectionView.deleteItemsAtIndexPaths([photo])
//            sharedContext.deleteObject(photo)
//        }
//        
//        self.saveContext()
        
//        var photosToDelete = [Photo]()
//        
//        //currentIndexPaths.append(indexPath)
//        
//        for indexPath in currentIndexPaths {
//            photosToDelete.append(pin.photos[indexPath.item])
//            collectionView.deleteItemsAtIndexPaths([indexPath])
//        }
//        
//        for photo in photosToDelete {
//            photo.pin = nil
//            sharedContext.deleteObject(photo)
//        }
//        
//        self.saveContext()
        
//        for indexPath in currentIndexPaths {
//            let photo = pin.photos[indexPath.item]
//    
//            photo.pin = nil
//    
//            collectionView.deleteItemsAtIndexPaths([indexPath])
//    
//            sharedContext.deleteObject(photo)
//            self.saveContext()
//        }
    }
}





