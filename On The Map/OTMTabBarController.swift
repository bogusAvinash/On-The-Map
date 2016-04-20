//
//  TabBarController.swift
//  On The Map
//
//  Created by Avinash Mudivedu on 4/7/16.
//  Copyright © 2016 Avinash Mudivedu. All rights reserved.
//

import UIKit

class OTMTabBarController: UITabBarController {
    
    @IBOutlet weak var logoutButton: UIBarButtonItem!
    @IBOutlet weak var addAPin: UIBarButtonItem!
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    
    @IBAction func addAPin(sender: AnyObject) {
        let viewController = storyboard!.instantiateViewControllerWithIdentifier("PostingViewController") 
        presentViewController(viewController, animated: true, completion: nil)
    }
    
    
    @IBAction func refreshButtonPressed(sender: AnyObject) {
        NSNotificationCenter.defaultCenter().postNotificationName(OTMClient.Notification.refreshData, object: nil)
    }

    func updateStudentInformation(viewController: UIViewController, view: UIView,
                                  completionHandlerForStudentInformation: (success: Bool, error: String?) -> Void) {
        if Reachability.isConnectedToNetwork() == true {
            OTMClient.sharedInstance().getStudentLocations(100, completionHandlerForLocation: { (success, error) in
                if success {
                    completionHandlerForStudentInformation(success: true, error: nil)
                } else {
                    completionHandlerForStudentInformation(success: false, error: "Could not download Data")
                }
            })
        }
        else {
            completionHandlerForStudentInformation(success: false, error: "No Internet Connection to update data.")
        }
    }
    
    
    // MARK: Shared Instance
    // This is to share the functions above with MapView and TableView
    class func sharedInstance() -> OTMTabBarController {
        struct Singleton {
            static var sharedInstance = OTMTabBarController()
        }
        return Singleton.sharedInstance
    }

}