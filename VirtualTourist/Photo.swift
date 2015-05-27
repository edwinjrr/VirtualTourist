//
//  Photo.swift
//  VirtualTourist
//
//  Created by Edwin Rodriguez on 5/26/15.
//  Copyright (c) 2015 Edwin Rodriguez. All rights reserved.
//

import Foundation

class Photo {
    
    var imageURL: String!

    init(dictionary: [String : AnyObject]) {
        imageURL = dictionary["url_m"] as! String
    }
    
    static func photosFromResults(results: [[String : AnyObject]]) -> [Photo] {
        
        var photos = [Photo]()
        var reducedResults = results[0...20]
        
        /* Iterate through array of dictionaries; each Student is a dictionary */
        for result in reducedResults {
            photos.append(Photo(dictionary: result))
        }
        
        return photos
    }
}