//
//  Pin.swift
//  VirtualTourist
//
//  Created by Edwin Rodriguez on 5/25/15.
//  Copyright (c) 2015 Edwin Rodriguez. All rights reserved.
//

import Foundation

class Pin {
    
    var latitude = 0.0
    var longitude = 0.0
    var locality = ""
    var administrativeArea = ""
    var country = ""
    
//    init(latitude: Double, longitude: Double, title: String, subtitle: String) {
//        self.latitude = latitude
//        self.longitude = longitude
//        self.title = title
//        self.subtitle = subtitle
//    }
    
    init(dictionary: [String : AnyObject]) {
        latitude = dictionary["latitude"] as! Double
        longitude = dictionary["longitude"] as! Double
        //locality = dictionary["locality"] as! String
        
        if let pinLocality = dictionary["locality"] as? String {
            locality = pinLocality
        }
        
        administrativeArea = dictionary["administrativeArea"] as! String
        country = dictionary["country"] as! String
    }
    
//    static func pinsFromMap(results: [[String : AnyObject]]) -> [Pin] {
//        
//        var pins = [Pin]()
//        
//        /* Iterate through array of dictionaries; each Student is a dictionary */
//        for result in results {
//            pins.append(Pin(dictionary: result))
//        }
//        
//        return pins
//    }
}