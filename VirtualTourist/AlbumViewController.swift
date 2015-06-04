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

class AlbumViewController: UIViewController, MKMapViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var coordinates: CLLocationCoordinate2D!

    var pin: Location!
    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected". The array is
    // used inside cellForItemAtIndexPath to lower the alpha of selected cells.  You can see how the array
    // works by searchign through the code for 'selectedIndexes'
    var selectedIndexes = [NSIndexPath]()
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var newCollection: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Insert the selected pin in the map view.
        setupMapView()
        
        // Start the fetched results controller
        var error: NSError?
        fetchedResultsController.performFetch(&error)
        
        if let error = error {
            println("Error performing initial fetch: \(error)")
        }
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
        
        println("-->Downloading Photos")
        
        let methodArguments = [
            "method": "flickr.photos.search",
            "api_key": "c9c5e79fe507f54c1e3a475194a43da6",
            "bbox": createBoundingBoxString(coordinates.latitude, longitude: coordinates.longitude),
            "safe_search": "1",
            "extras": "url_m",
            "format": "json",
            "nojsoncallback": "1"
        ]
        
        Flickr.sharedInstance().getImageFromFlickrBySearch(methodArguments) {(results, error) in
            
            if let error = error {
                println("Setup an alert view here") //<--- Setup an AlertView here!
            }
            else {
                
                if let photosDictionaries = results as [[String : AnyObject]]? {
                    
                    // Parse the array of photos dictionaries
                    var photos = photosDictionaries.map() { (dictionary: [String : AnyObject]) -> Photo in
                        
                        let photo = Photo(dictionary: dictionary, context: self.sharedContext)
                        
                        photo.pin = self.pin
                        
                        return photo
                    }
                    
                    // Update the collection on the main thread
                    dispatch_async(dispatch_get_main_queue()) {
                        self.activityIndicator.stopAnimating()
                        self.collectionView.reloadData()
                    }
                    
                    // Save the context
                    self.saveContext()
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
    
    // MARK: - NSFetchedResultsController
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
        }()
    
    // MARK: - UICollectionView
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        //return pin.photos.count
        
        let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        
        self.numberOfPhotosDownloaded = sectionInfo.numberOfObjects
        
        return sectionInfo.numberOfObjects
    }
    
    var numberOfPhotosVisible: Int = 0
    var numberOfPhotosDownloaded: Int = 0
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        //let photo = pin.photos[indexPath.item]
        //let cellIdentifier = "PhotoViewCell"
        //var photoImage = UIImage(named: "placeholder")
        
        let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoViewCell", forIndexPath: indexPath) as! PhotoCell
        
        cell.loadingIndicator.startAnimating()
        cell.backgroundColor = UIColor.grayColor()
        
        let queue:dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
        dispatch_async(queue, { () -> Void in
        
            if photo.photoImage != nil {
                
                //println("Using the image saved")
                
                //photoImage = photo.photoImage
                
                dispatch_async(dispatch_get_main_queue(), {
                    cell.imageView.image = photo.photoImage
                    cell.loadingIndicator.stopAnimating()
                    
                    self.numberOfPhotosVisible += 1
                    
                    if self.numberOfPhotosDownloaded == self.numberOfPhotosVisible {
                        self.newCollection.enabled = true
                        self.numberOfPhotosDownloaded = 0
                    }
                })
                
            } else {

                //println("Calling the image url")
                
                let imageURL = NSURL(string: photo.imageURL)
                
                let imageData = NSData(contentsOfURL: imageURL!)
                
                //Create the image
                let image = UIImage(data: imageData!)
                
                //Update the model
                photo.photoImage = image
                
                dispatch_async(dispatch_get_main_queue(), {
                    cell.imageView.image = image
                    cell.loadingIndicator.stopAnimating()
                    
                    self.numberOfPhotosVisible += 1
                    
                    if self.numberOfPhotosDownloaded == self.numberOfPhotosVisible {
                        self.newCollection.enabled = true
                        self.numberOfPhotosDownloaded = 0
                    }
                })
            }
        })
        
        //cell.imageView.image = photo.photoImage
        
        self.configureCell(cell, atIndexPath: indexPath)
        
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
        
//        let photo = pin.photos[indexPath.item]
//        
//        photo.pin = nil
//        
//        collectionView.deleteItemsAtIndexPaths([indexPath])
//        
//        sharedContext.deleteObject(photo)
//        self.saveContext()
        
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
    
    @IBAction func deleteSelectedPhotos() {
        var photosToDelete = [Photo]()
        
        for indexPath in selectedIndexes {
            photosToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
        
        for photo in photosToDelete {
            sharedContext.deleteObject(photo)
        }
        
        selectedIndexes = [NSIndexPath]()
    }
    
    @IBAction func deleteAllPhotos(sender: AnyObject) {
        
        for photo in fetchedResultsController.fetchedObjects as! [Photo] {
            sharedContext.deleteObject(photo)
        }
        
        downloadPhotos()
        
    }
    
    func updateDeleteButton() {
        if selectedIndexes.count > 0 {
            deleteButton.enabled = true
        } else {
            deleteButton.enabled = false
        }
    }
    
    // MARK: - Fetched Results Controller Delegate
    
    // Whenever changes are made to Core Data the following three methods are invoked. This first method is used to create
    // three fresh arrays to record the index paths that will be changed.
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
        println("in controllerWillChangeContent")
    }
    
    // The second method may be called multiple times, once for each Color object that is added, deleted, or changed.
    // We store the incex paths into the three arrays.
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
            
        case .Insert:
            println("Insert an item")
            // Here we are noting that a new Color instance has been added to Core Data. We remember its index path
            // so that we can add a cell in "controllerDidChangeContent". Note that the "newIndexPath" parameter has
            // the index path that we want in this case
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            println("Delete an item")
            // Here we are noting that a Color instance has been deleted from Core Data. We keep remember its index path
            // so that we can remove the corresponding cell in "controllerDidChangeContent". The "indexPath" parameter has
            // value that we want in this case.
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            println("Update an item.")
            // We don't expect Color instances to change after they are created. But Core Data would
            // notify us of changes if any occured. This can be useful if you want to respond to changes
            // that come about after data is downloaded. For example, when an images is downloaded from
            // Flickr in the Virtual Tourist app
            updatedIndexPaths.append(indexPath!)
            break
        case .Move:
            println("Move an item. We don't expect to see this in this app.")
            break
        default:
            break
        }
    }
    
    // This method is invoked after all of the changed in the current batch have been collected
    // into the three index path arrays (insert, delete, and upate). We now need to loop through the
    // arrays and perform the changes.
    //
    // The most interesting thing about the method is the collection view's "performBatchUpdates" method.
    // Notice that all of the changes are performed inside a closure that is handed to the collection view.
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        println("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }
}


