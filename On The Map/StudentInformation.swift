//
//  Student.swift
//  On The Map
//
//  Created by Avinash Mudivedu on 4/13/16.
//  Copyright © 2016 Avinash Mudivedu. All rights reserved.
//

import Foundation

struct StudentInformation {
    
    var objectId:String?
    let uniqueKey: String
    let firstName: String
    let lastName: String
    var mapString: String?
    var mediaURL: String?
    var latitude: Double?
    var longtitude: Double?
    
    init(uniqueKey: String, firstName: String, lastName: String) {
        self.uniqueKey = uniqueKey
        self.firstName = firstName
        self.lastName = lastName
        
    }
    
    static var studentInformation = [StudentInformation]()
    
    
    // Mark: - Initializers
    
    // Construct a StudentInformation from a dictionary
    init(dictionary: [String : AnyObject]) {
        
        objectId = dictionary[OTMClient.HTTPBodyKeys.objectId] as! String?
        uniqueKey = dictionary[OTMClient.HTTPBodyKeys.uniqueKey] as! String
        firstName = dictionary[OTMClient.HTTPBodyKeys.firstName] as! String
        lastName = dictionary[OTMClient.HTTPBodyKeys.lastName] as! String
        
        mapString = dictionary[OTMClient.HTTPBodyKeys.mapString] as! String?
        mediaURL = dictionary[OTMClient.HTTPBodyKeys.mediaURL] as! String?
        latitude = dictionary[OTMClient.HTTPBodyKeys.latitude] as! Double?
        longtitude = dictionary[OTMClient.HTTPBodyKeys.longitude] as! Double?
    }
    
    static func studentInformationFromResults(results: [[String:AnyObject]]) -> [StudentInformation] {
        var students = [StudentInformation]()
        
        for result in results {
            students.append(StudentInformation(dictionary: result))
        }
        
        return students
    }
    
}