//
//  HTWTrack.swift
//  HTWcampus
//
//  Created by Benjamin Herzog on 21/02/16.
//  Copyright © 2016 Benjamin Herzog. All rights reserved.
//

import UIKit

@objc enum TrackType: Int {
    case Start, Open
}

enum Platform: Int {
    case Android, iOS
}

@objc class HTWTrack: NSObject {
    
    class func track(type: TrackType) {
        
        let r = NSMutableURLRequest(URL: NSURL(string: "http://track.benchr.de/track")!)
        
        r.HTTPMethod = "POST"
        
        let p = [
            "plattform": Platform.iOS.rawValue,
            "api": UIDevice.currentDevice().systemVersion,
            "version": NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String,
            "unique": UIDevice.currentDevice().identifierForVendor?.UUIDString ?? "unkown",
            "type": type.rawValue
        ]
        
        let d = try? NSJSONSerialization.dataWithJSONObject(p, options: .PrettyPrinted)
        r.HTTPBody = d
        r.setValue(d?.length.description ?? "0", forHTTPHeaderField: "Content-Length")
        
        NSURLSession.sharedSession().dataTaskWithRequest(r) {
            d, r, e in
            
            if let e = e {
                print(e)
                return
            }
            
            print((r as? NSHTTPURLResponse)?.statusCode)
            print(String(data: d!, encoding: NSUTF8StringEncoding))
        }.resume()
    }
}
