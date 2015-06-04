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
    @NSManaged var pin: Location?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        imageURL = dictionary["url_m"] as! String
    }
    
    var photoImage: UIImage? {
        
        get {
            return Flickr.Caches.imageCache.imageWithIdentifier(imageURL)
        }
        
        set {
            Flickr.Caches.imageCache.storeImage(newValue, withIdentifier: imageURL)
        }
    }
}