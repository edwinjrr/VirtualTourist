//
//  Flickr.swift
//  VirtualTourist
//
//  Created by Edwin Rodriguez on 5/25/15.
//  Copyright (c) 2015 Edwin Rodriguez. All rights reserved.
//

import Foundation

class Flickr {
    
    /* Shared session */
    var session: NSURLSession
    
    init() {
        session = NSURLSession.sharedSession()
    }
    
    /* Function makes first request to get a random page, then it makes a request to get an image with the random page */
    func getImageFromFlickrBySearch(methodArguments: [String : AnyObject], completionHandler: (result: [Photo]?, error: String?) -> Void) {
        
        let session = NSURLSession.sharedSession()
        let urlString = "https://api.flickr.com/services/rest/" + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                completionHandler(result: nil, error: "Could not find photos")
            } else {
                
                 /* Parsing the data */
                var parsingError: NSError? = nil
                let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
                
                /* Using the data! */
                if let photosDictionary = parsedResult.valueForKey("photos") as? [String:AnyObject] {
                    
                    if let totalPages = photosDictionary["pages"] as? Int {
                        
                        /* Flickr API - will only return up the 4000 images (100 per page * 40 page max) */
                        let pageLimit = min(totalPages, 40)
                        let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                        self.getImageFromFlickrBySearchWithPage(methodArguments, pageNumber: randomPage) { (results, error) in
                            if let results = results {
                                completionHandler(result: results, error: nil)
                            }
                            else {
                                completionHandler(result: nil, error: "1,2,3...error...")
                            }
                        }
                    } else {
                        completionHandler(result: nil, error: "Cant find key 'pages'")
                    }
                } else {
                    completionHandler(result: nil, error: "Cant find key 'photos'")
                }
            }
        }
        
        task.resume()
    }
    
    func getImageFromFlickrBySearchWithPage(methodArguments: [String : AnyObject], pageNumber: Int, completionHandler: (result: [Photo]?, error: String?) -> Void) {
        
        /* Add the page to the method's arguments */
        var withPageDictionary = methodArguments
        withPageDictionary["page"] = pageNumber
        
        let session = NSURLSession.sharedSession()
        let urlString = "https://api.flickr.com/services/rest/" + escapedParameters(withPageDictionary)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                completionHandler(result: nil, error: "Could not complete the request")
            } else {
                var parsingError: NSError? = nil
                let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
                
                if let photosDictionary = parsedResult.valueForKey("photos") as? [String:AnyObject] {
                    
                    var totalPhotosVal = 0
                    if let totalPhotos = photosDictionary["total"] as? String {
                        totalPhotosVal = (totalPhotos as NSString).integerValue
                    }
                    
                    if totalPhotosVal > 0 {
                        if let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] {
                            
                            //let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                            //let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]
                            
                            var photos = Photo.photosFromResults(photosArray)
                            
                            completionHandler(result: photos, error: nil)
                            
//                            let imageUrlString = photoDictionary["url_m"] as? String
//                            let imageURL = NSURL(string: imageUrlString!)
//                            
//                            if let imageData = NSData(contentsOfURL: imageURL!) {
//                                completionHandler(result: imageData, error: nil)
//                                
//                            } else {
//                                completionHandler(result: nil, error: "Image does not exist at \(imageURL)")
//                            }
                        } else {
                            completionHandler(result: nil, error: "Cant find key 'photo' in \(photosDictionary)")
                        }
                    } else {
                        completionHandler(result: nil, error: "error...")
                    }
                } else {
                    completionHandler(result: nil, error: "Cant find key 'photos' in \(parsedResult)")
                }
            }
        }
        
        task.resume()
    }
    
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
    }
    
    // MARK: - Shared Instance
    
    class func sharedInstance() -> Flickr {
        
        struct Singleton {
            static var sharedInstance = Flickr()
        }
        
        return Singleton.sharedInstance
    }
}