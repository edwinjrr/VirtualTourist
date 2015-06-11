//
//  Photo.swift
//  VirtualTourist
//
//  Created by Edwin Rodriguez on 5/26/15.
//  Copyright (c) 2015 Edwin Rodriguez. All rights reserved.
//

import UIKit
import MapKit
import CoreData

@objc(Photo)

class Photo: NSManagedObject {
    
    @NSManaged var imageURL: String
    @NSManaged var imageID: String
    @NSManaged var pin: Location?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    convenience init(dictionary: [String : AnyObject], insertIntoMangedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        imageURL = dictionary["url_m"] as! String
        imageID = dictionary["id"] as! String
    }
    
    //This property will get and save the images of the photos from/to the documents directory.
    var photoImage: UIImage? {
        
        get {
            return Flickr.Caches.imageCache.imageWithIdentifier("\(imageID).jpg")
        }
        
        set {
            Flickr.Caches.imageCache.storeImage(newValue, withIdentifier: "\(imageID).jpg")
        }
    }
}