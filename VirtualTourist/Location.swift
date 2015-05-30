//
//  Location.swift
//  VirtualTourist
//
//  Created by Edwin Rodriguez on 5/29/15.
//  Copyright (c) 2015 Edwin Rodriguez. All rights reserved.
//

import Foundation
import MapKit
import CoreData
import CoreLocation

@objc(Location)

class Location: NSManagedObject, MKAnnotation {
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(latitude, longitude)
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("Location", inManagedObjectContext: context)!
        
        super.init(entity: entity,insertIntoManagedObjectContext: context)
    }
}
