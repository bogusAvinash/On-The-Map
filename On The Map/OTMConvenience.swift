//
//  OTMConvenience.swift
//  On The Map
//
//  Created by Avinash Mudivedu on 4/12/16.
//  Copyright © 2016 Avinash Mudivedu. All rights reserved.
//

import UIKit

extension OTMClient {
    
    func authenticateWithUdacity(userName: String?, password: String?, completionHandlerForAuth: (success: Bool, errorString: String?) -> Void) {
        if (userName!.isEmpty || password!.isEmpty) {
            // Text fields are empty and fail.
            completionHandlerForAuth(success: false, errorString: "Username or Password is empty.")
        } else {
            if Reachability.isConnectedToNetwork(){
                // Everything is good so far, continue.
                
                getSessionID(userName, password: password, completionHandlerForSession: { (success, errorString) in
                    if (success) {
                        
                        self.getPublicUserData(self.uniqueKey, completionHandlerForUserData: { (success, student, error) in
                            if success {
                                completionHandlerForAuth(success: true, errorString: nil)
                            } else {
                                completionHandlerForAuth(success: false, errorString: "Could not get User Data")
                            }
                        })
                        
                    }
                    else {
                        completionHandlerForAuth(success: false, errorString: "Wrong Username or Password.")
                    }
                })
            }
            else {
                // Internet Connection fails.
                print("Internet connection FAILED")
                completionHandlerForAuth(success: false, errorString: "Internet Connection Failed")
            }
            
        }
    }
    
    // Check if the URL is a correct URL, if not, add a "http://".
    func formatURL(urlString: String, completionHandlerForURL: (success: Bool, newURL: String?, error: String?) -> Void) {
        if UIApplication.sharedApplication().canOpenURL(NSURL(string: urlString)!) {
            completionHandlerForURL(success: true, newURL: urlString, error: nil)
        } else {
            if !(urlString.lowercaseString.hasPrefix("http://")) {
                let newURL = "http://" + urlString
                print(newURL)
                if UIApplication.sharedApplication().canOpenURL(NSURL(string: newURL)!) {
                    completionHandlerForURL(success: true, newURL: newURL, error: nil)
                } else {
                    completionHandlerForURL(success: false, newURL: nil, error: "URL is incorrect")
                }
            } else {
                completionHandlerForURL(success: false, newURL: nil, error: "URL is incorrect")
            }
        }
        
    }
    
    // MARK: - UDACITY
    // API Usage: https://docs.google.com/document/d/1MECZgeASBDYrbBg7RlRu9zBBLGd3_kfzsN-0FtURqn0/pub?embedded=true
    
    // POSTing (Creating) a Session
    private func getSessionID(userName: String?, password: String?, completionHandlerForSession: (success: Bool, errorString: NSError?) -> Void) {
        
        
        let mutableMethod: String = Methods.AuthorizationURL
        let udacityBody: [String:AnyObject] = [HTTPBodyKeys.Username: userName!, HTTPBodyKeys.Password: password!]
        let jsonBody: [String:AnyObject] = [HTTPBodyKeys.Udacity: udacityBody]
        
        
        taskForPOSTMethod(mutableMethod, udacity: true, parameters: nil, jsonBody: jsonBody) { (result, error) in
            if let error = error {
                completionHandlerForSession(success: false, errorString: error)
                
            } else {
                if let id = result.valueForKey(JSONResponseKeys.Session)?.valueForKey(JSONResponseKeys.Id) as? String {
                    self.sessionID = id
                    if let key = result.valueForKey(JSONResponseKeys.Account)?.valueForKey(JSONResponseKeys.Key) as? String {
                        self.uniqueKey = key
                    }
                    completionHandlerForSession(success: true, errorString: nil)
                }
                else {
                    completionHandlerForSession(success: false, errorString: NSError(domain: "getSession Parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse getSessionID result"]))
                    
                }
                
            }
        }
        
    }
    
    // GETting Public User Data
    private func getPublicUserData(uniqueKey: String?, completionHandlerForUserData: (success: Bool, student: StudentInformation?, error: NSError?) -> Void) {
        
        let parameters: [String:AnyObject] = [String:AnyObject]()
        let method = Methods.UserDataURL + uniqueKey!
        
        taskForGETMethod(method, udacity: true, parameters: parameters) { (result, error) in
            
            if let error = error {
                completionHandlerForUserData(success: true, student: nil, error: NSError(domain: "Failed to get User Data", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse getPublicUserData"]))
            } else {
                
                if let lastName = result.valueForKey(JSONResponseKeys.User)?.valueForKey(JSONResponseKeys.Last_Name) as? String {
                    if let firstName = result.valueForKey(JSONResponseKeys.User)?.valueForKey(JSONResponseKeys.First_Name) as? String {
                        if let uniqueKey = result.valueForKey(JSONResponseKeys.User)?.valueForKey(JSONResponseKeys.Key) as? String {
                            self.currentStudent = StudentInformation(uniqueKey: uniqueKey, firstName: firstName, lastName: lastName)
                            completionHandlerForUserData(success: true, student: self.currentStudent, error: nil)
                        }
                    }
                } else {
                    completionHandlerForUserData(success: true, student: nil, error: NSError(domain: "Failed to get User Data", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse getPublicUserData"]))
                }
 
                
                

                
                
            }
        }
    }
    
    


    // MARK: - PARSE
    // API Usage: https://docs.google.com/document/d/1E7JIiRxFR3nBiUUzkKal44l9JkSyqNWvQrNH4pDrOFU/pub?embedded=true
    
    
    func getStudentLocations(limit: Int?, completionHandlerForLocation: (success: Bool, error: String?) -> Void) {
        
        let parameters: [String:AnyObject] = [
            "limit": limit!,
            "skip": 0,
            "order": "-updatedAt"
        ]
        
        let method = Methods.Parse.StudentLocations + OTMClient.escapedParameters(parameters)
        
        taskForGETMethod(method, udacity: false, parameters: nil) { (result, error) in
            
            if let error = error {
                completionHandlerForLocation(success: false, error: "Failed to get Student Locations")
            } else {
                if let results = result.valueForKey(JSONResponseKeys.Results) as? [[String:AnyObject]] {
                    StudentInformation.studentInformation = StudentInformation.studentInformationFromResults(results)
                    completionHandlerForLocation(success: true, error: nil)
                    
                } else {
                    completionHandlerForLocation(success: false, error: "Failed to get StudentInformation")
                }
            }
        }
        
    }
    
    func postAStudentLocation(updatedStudent: StudentInformation?, completionHandlerForStudentLocation: (success: Bool, error: String?) -> Void) {
        
        let method = Methods.Parse.StudentLocations
        let currentStudent = OTMClient.sharedInstance().currentStudent
        
        let jsonBody: [String:AnyObject] = [
            OTMClient.JSONBodyKeys.UniqueKey: currentStudent!.uniqueKey,
            OTMClient.JSONBodyKeys.FirstName: "Minh",
            OTMClient.JSONBodyKeys.LastName: "Benham",

            //OTMClient.JSONBodyKeys.FirstName: currentStudent!.firstName,
            //OTMClient.JSONBodyKeys.LastName: currentStudent!.lastName,
            OTMClient.JSONBodyKeys.MapString: updatedStudent!.mapString!,
            OTMClient.JSONBodyKeys.MediaURL: updatedStudent!.mediaURL!,
            OTMClient.JSONBodyKeys.Latitude: updatedStudent!.latitude!,
            OTMClient.JSONBodyKeys.Longitude: updatedStudent!.longtitude!
        ]
        
        taskForPOSTMethod(method, udacity: false, parameters: nil, jsonBody: jsonBody) { (result, error) in
            if let error = error {
                completionHandlerForStudentLocation(success: false, error: "Error Posting Data")
            } else {
                if let objectID = result.valueForKey("objectId") as? String {
                    print(objectID)
                    completionHandlerForStudentLocation(success: true, error: nil)
//                    print(NSString(data: result, encoding: NSUTF8StringEncoding))
                } else {
                    completionHandlerForStudentLocation(success: false, error: "Could not post location")
                }
            }
        }
//        completionHandlerForStudentLocation(success: true, error: nil)
        
    }

}

