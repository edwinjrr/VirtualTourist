//
//  Photo.swift
//  VirtualTourist
//
//  Created by Edwin Rodriguez on 5/26/15.
//  Copyright (c) 2015 Edwin Rodriguez. All rights reserved.
//

import Foundation

//farm = 6;
//"height_m" = 333;
//id = 17336101419;
//isfamily = 0;
//isfriend = 0;
//ispublic = 1;
//owner = "63054128@N02";
//secret = 5788a4629b;
//server = 5322;
//title = "Pallets of bananas travel along the conveyor to the automatic turntable";
//"url_m" = "https://farm6.staticflickr.com/5322/17336101419_5788a4629b.jpg";
//"width_m" = 500;
//},

class Photo {
    
    var imageURL: String!

    init(dictionary: [String : AnyObject]) {
        imageURL = dictionary["url_m"] as! String
    }
    
    static func photosFromResults(results: [[String : AnyObject]]) -> [Photo] {
        
        var photos = [Photo]()
        var reducedResults = results[0...5]
        
        /* Iterate through array of dictionaries; each Student is a dictionary */
        for result in reducedResults {
            photos.append(Photo(dictionary: result))
        }
        
        return photos
    }
}