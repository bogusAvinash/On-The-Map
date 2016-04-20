//
//  MapViewController.swift
//  On The Map
//
//  Created by Avinash Mudivedu on 4/7/16.
//  Copyright © 2016 Avinash Mudivedu. All rights reserved.
//

import UIKit
import MapKit

class OTMMapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        // Initial Download Data
        updateMapData(nil)
        
        // Watch for Refresh Button Pushes on Tab Bar Controller and update data accordingly
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateMapData:", name: OTMClient.Notification.refreshData, object: nil)

        
    }

    
    func updateMapData(notification: NSNotification?) {
        OTMTabBarController.sharedInstance().updateStudentInformation(self, view: view) { (success, error) in
            if success {
                performUIUpdatesOnMain({
                    self.addAnnotations()
                })
            } else {
                print("error")
            }
        }
    }
    


    private func addAnnotations(){
        
        var annotations = [MKPointAnnotation]()
        
        for student in StudentInformation.studentInformation {
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: student.latitude!, longitude: student.longtitude!)
            annotation.title = student.firstName + " " + student.lastName
            annotation.subtitle = student.mediaURL
            
            annotations.append(annotation)
        }
        
        //performUIUpdatesOnMain {
            self.mapView.removeAnnotations(self.mapView.annotations)
            self.mapView.addAnnotations(annotations)
        //}
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "studentPin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            //pinView!.pinTintColor = UIColor.blueColor()
            pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            
            OTMClient.sharedInstance().formatURL(((view.annotation?.subtitle)!)!, completionHandlerForURL: { (success, newURL, error) in
                if success {
                    UIApplication.sharedApplication().openURL(NSURL(string: newURL!)!)
                } else {
                    print(error)
                }
                
            })
        }
    }


}