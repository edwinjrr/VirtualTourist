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
    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected". The array is
    // used inside cellForItemAtIndexPath to lower the alpha of selected cells.  You can see how the array
    // works by searchign through the code for 'selectedIndexes'
    var selectedIndexes = [NSIndexPath]()
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    var pin: Location!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var deleteButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Insert the selected pin in the map view.
        setupMapView()
        
        // Step 2: Perform the fetch
        fetchedResultsController.performFetch(nil)
        
        // Step 6: Set the delegate to this view controller
        fetchedResultsController.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
    
        //Download the images to populate the collection view.
        
        if pin.photos.isEmpty {
            downloadPhotos()
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
    
    // MARK: - Core Data Convenience
    
    lazy var sharedContext: NSManagedObjectContext =  {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
        }()
    
        func saveContext() {
            CoreDataStackManager.sharedInstance().saveContext()
        }
    
    // MARK: - Configure Cell
    
    func configureCell(cell: PhotoCell, atIndexPath indexPath: NSIndexPath, photo: Photo) {
        
        cell.backgroundColor = UIColor.grayColor()
        cell.imageView.image = nil
        cell.loadingIndicator.startAnimating()
        
        let queue:dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
        //dispatch_async(queue, { () -> Void in
        
        if photo.photoImage != nil {
            
            println("Using the image saved")
            cell.loadingIndicator.stopAnimating()
            cell.imageView.image = photo.photoImage
            
        } else {

                cell.loadingIndicator.startAnimating()
                cell.backgroundColor = UIColor.grayColor()

                println("Calling the image url")
                
                let imageURL = NSURL(string: photo.imageURL)
                
                let imageData = NSData(contentsOfURL: imageURL!)
                
                //Create the image
                let image = UIImage(data: imageData!)
                
                //Update the model
                photo.photoImage = image
                
                dispatch_async(dispatch_get_main_queue(), {
                    cell.imageView.image = image
                    cell.loadingIndicator.stopAnimating()
                    
                    //return
                })
            }
        //})
        
        cell.imageView!.image = photo.photoImage
        
        // If the cell is "selected" it's color panel is grayed out
        // we use the Swift `find` function to see if the indexPath is in the array
        
        if let index = find(selectedIndexes, indexPath) {
            cell.imageView.alpha = 0.25
        } else {
            cell.imageView.alpha = 1.0
        }
    }
    
    // MARK: - UICollectionView
    
//    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
//        return self.fetchedResultsController.sections?.count ?? 0
//    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        
        println("number Of Cells: \(sectionInfo.numberOfObjects)")
        
        return sectionInfo.numberOfObjects
        
        //return pin.photos.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoViewCell", forIndexPath: indexPath) as! PhotoCell
        
        // Here is how to replace the actors array using objectAtIndexPath
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        self.configureCell(cell, atIndexPath: indexPath, photo: photo)
        
        return cell
    }
    
//    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
//        
//        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoViewCell", forIndexPath: indexPath) as! PhotoCell
//        
//        //cell.backgroundColor = UIColor.blackColor()
//        cell.loadingIndicator.startAnimating()
//        cell.imageView.image = nil
//        
//        let queue:dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
//        
//        dispatch_async(queue, { () -> Void in
//            
//            let imageURL = NSURL(string: photo.imageURL)
//    
//            //let imageData = NSData(contentsOfURL: imageURL!)
//    
//            //cell.imageView.image = UIImage(data: imageData!)
//    
//            var error:NSError?
//    
//            if error == nil{
//    
//                if let imageData = NSData(contentsOfURL: imageURL!) {
//    
//                    let image = UIImage(data: imageData)
//    
//                    dispatch_async(dispatch_get_main_queue(), {
//                        cell.imageView.image = image
//                        cell.loadingIndicator.stopAnimating()
//                        
//                        return
//                    })
//                }
//            }
//            
//            //self.configureCell(cell, atIndexPath: indexPath)
//        })
//        
//        return cell
//    }
    
    
//    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
//        
//        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
//        
//        // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
//        if let index = find(selectedIndexes, indexPath) {
//            selectedIndexes.removeAtIndex(index)
//        } else {
//            selectedIndexes.append(indexPath)
//        }
//        
//        // Then reconfigure the cell
//        configureCell(cell, atIndexPath: indexPath)
//        
//        // And update the buttom button
//        updateDeleteButton()
//    }
    
    // MARK: - NSFetchedResultsController
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "imageURL", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin);
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        //fetchedResultsController.delegate = self
        
        return fetchedResultsController
        }()
    
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
    // We store the index paths into the three arrays.
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

    // MARK: - Actions and Helpers
    
    @IBAction func downloadNewCollection(sender: AnyObject) {
        //--->Empty by now!
    }
    
    //Show the pin selected in the small map view on top of the view controller.
    func setupMapView() {
        let regionRadius: CLLocationDistance = 20000
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinates, regionRadius, regionRadius)
        self.mapView.setRegion(coordinateRegion, animated: true)
        var pinAnnotation = MKPointAnnotation()
        pinAnnotation.coordinate = coordinates
        self.mapView.addAnnotation(pinAnnotation)
    }
    
    func downloadPhotos() {
        
        println("--->Downloading Photos<----")
        
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
                        self.collectionView.reloadData()
                    }
                    
                    // Save the context
                    self.saveContext()
                }
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
    
    func updateDeleteButton() {
        if selectedIndexes.count > 0 {
            deleteButton.enabled = true
        }
        else {
            deleteButton.enabled = false
        }
    }
    
    @IBAction func deleteSelectedPhotos() {
        
        if !selectedIndexes.isEmpty {
            deleteAllPhotos()
        }
    }
    
    func deleteAllPhotos() {
        
        for photo in fetchedResultsController.fetchedObjects as! [Photo] {
            sharedContext.deleteObject(photo)
        }
    }
}


