//
//  OTMClient.swift
//  On The Map
//
//  Created by Avinash Mudivedu on 4/12/16.
//  Copyright © 2016 Avinash Mudivedu. All rights reserved.
//

import Foundation

class OTMClient: NSObject {
    
    // MARK: Properties
    
    // shared session
    var session = NSURLSession.sharedSession()
    
    // authentication state
    var sessionID: String? = nil
    var uniqueKey: String? = nil
    var currentStudent: StudentInformation? = nil
    var students: [StudentInformation]? = nil
    
    // Store the data in a central spot
    var studentInformation: [StudentInformation] = [StudentInformation]()
    
    // MARK: Initializers
    
    override init() {
        super.init()
    }
    
    // MARK: - POST
    
    func taskForPOSTMethod(method: String, udacity: Bool, parameters: [String:AnyObject]?, jsonBody: [String:AnyObject], completionHandlerForPOST: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        /* 1. Set the parameters */
        var urlString: String
        
        if let methodParameters = parameters {
            urlString = method + OTMClient.escapedParameters(methodParameters)
        } else {
            urlString = method
        }
        
        /* 2/3. Build the URL, Configure the request */
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        
        /* Is the request Udacity or Parse? */
        if udacity {
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
        } else {
            request.addValue("QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr", forHTTPHeaderField: "X-Parse-Application-Id")
            request.addValue("QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY", forHTTPHeaderField: "X-Parse-REST-API-Key")
        }
        
        do {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(jsonBody, options: [])
        } catch _ as NSError {
            request.HTTPBody = nil
        }
        
    
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            if let JSONError = error {
                
                _ = OTMClient.errorForData(data, response: response, error: JSONError)
                print(error)
                completionHandlerForPOST(result: nil, error: error)
            } else {
                var newData = data
                if(udacity){
                    newData = data!.subdataWithRange(NSMakeRange(5, data!.length - 5)) 
                }
                /* 5/6. Parse the data and use the data (happens in completion handler) */
                self.convertDataWithCompletionHandler(newData!, completionHandlerForConvertData: completionHandlerForPOST)
            }
            
        }
        
        /* 7. Start the request */
        task.resume()
        
        return task
    }
    
    // MARK: - GET
    
    func taskForGETMethod(method: String, udacity: Bool, parameters: [String:AnyObject]?, completionHandlerForGET: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        var urlString: String
        
        if let mutableParameters = parameters {
            urlString = method + OTMClient.escapedParameters(mutableParameters)
        } else {
            urlString = method
        }
        
        let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        
        if (!udacity) {
            request.addValue("QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr", forHTTPHeaderField: "X-Parse-Application-Id")
            request.addValue("QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY", forHTTPHeaderField: "X-Parse-REST-API-Key")

        }
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            if let dataError = error {
                OTMClient.errorForData(data, response: response, error: dataError)
                completionHandlerForGET(result: nil, error: dataError)
            } else {
                var newData = data
                if(udacity){
                    newData = data!.subdataWithRange(NSMakeRange(5, data!.length - 5)) /* subset response data! */
                }
                self.convertDataWithCompletionHandler(newData!, completionHandlerForConvertData: completionHandlerForGET)
            }
        }
        task.resume()
        
        return task
    }
    
    // given raw JSON, return a usable Foundation object
    private func convertDataWithCompletionHandler(data: NSData, completionHandlerForConvertData: (result: AnyObject!, error: NSError?) -> Void) {
        
        var parsedResult: AnyObject!
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(result: nil, error: NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForConvertData(result: parsedResult, error: nil)
    }
    
    // MARK: Helper for error, see if a status_message is returned, otherwise return the previous error
    class func errorForData(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError {
        
        if let parsedResult = (try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)) as? [String : AnyObject] {
            
            if let errorMessage = parsedResult[OTMClient.JSONResponseKeys.StatusMessage] as? String {
                let userInfo = [NSLocalizedDescriptionKey : errorMessage]
                return NSError(domain: "On The Map Error", code: 1, userInfo: userInfo)
            }
        }
        
        return error
    }
    
    // MARK: Helper for Escaping Parameters in URL
    
    class func escapedParameters(parameters: [String:AnyObject]) -> String {
        
        if parameters.isEmpty {
            return ""
        } else {
            var keyValuePairs = [String]()
            
            for (key, value) in parameters {
                
                // make sure that it is a string value
                let stringValue = "\(value)"
                
                // escape it
                let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
                
                // append it
                keyValuePairs.append(key + "=" + "\(escapedValue!)")
                
            }
            
            return "?\(keyValuePairs.joinWithSeparator("&"))"
        }
    }
    
    // MARK: Shared Instance
    
    class func sharedInstance() -> OTMClient {
        struct Singleton {
            static var sharedInstance = OTMClient()
        }
        return Singleton.sharedInstance
    }
}