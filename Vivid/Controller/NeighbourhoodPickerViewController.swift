//
//  NeighbourhoodPickerViewController.swift
//  Vivid
//
//  Created by Celia Gómez de Villavedón on 03/07/2017.
//  Copyright © 2017 Celia Gómez de Villavedón Pedrosa. All rights reserved.
//

import UIKit
import SearchTextField
import MapKit
import Sync


//MARK: NeighbourhoodPickerViewController: UIViewController

class NeighbourhoodPickerViewController: UIViewController, UITextFieldDelegate {

    //MARK: Outlets
    @IBOutlet weak var mySearchTextField: SearchTextField!
    
    var neighbourhoods: [String]!
    var userLocation: String?
    var searchTask: URLSessionDataTask?
    
    
    //MARK: Neighbourhood enumeration
    
    enum Neighbourhood: String {
        case currentLocation = "Current location", neukölln = "Neukölln", kreuzberg = "Kreuzberg", mitte = "Mitte"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mySearchTextField.delegate = self
        
        //Receive Notification from MapViewController - User Location
        NotificationCenter.default.addObserver(self, selector: #selector(locationUpdateNotification), name: Notification.Name("UserLocationNotification"), object: nil)
        
        neighbourhoods = [Neighbourhood.currentLocation.rawValue, Neighbourhood.kreuzberg.rawValue, Neighbourhood.neukölln.rawValue, Neighbourhood.mitte.rawValue]
        
        neighbourhoodPickerConfig(neighbourhoods: neighbourhoods)
        
        GMSClient.sharedInstance().getDataFromGMSApi { (results, error) in
            
            guard error == nil else {
                print(error ?? "error getting data from gms api")
                return
            }
            
            guard let results = results else {
                print("No results")
                return
            }
            
            guard let thumbPhotos = results["thumbPhotos"] as? [String], let largePhotos = results["largePhotos"] as? [String], let name = results["name"] as? String else {
                print("Could not find thumbPhotos o largePhotos in results")
                return
            }
            
            let modelResults = Model.sharedInstance().fetchManagedObject()
            
            guard !modelResults.isEmpty else {
                print("Model results is empty")
                return
            }
            
            for modelResult in modelResults as! [NSManagedObject] {
                
                guard let modelName = modelResult.value(forKey: "name") as? String else {
                    print("Could not find modelName as String")
                    return
                }
                
                if modelName == name {
                    Model.sharedInstance().storeLargePhotos(modelResult, largePhotos)
                    Model.sharedInstance().storeThumbPhotos(modelResult, thumbPhotos)
                } else {
                    print("modelName and resultsName didn't match")
                }
            }
        }
    }

    func locationUpdateNotification(notification: NSNotification) {

        if let userInfo = notification.userInfo?["location"] as? CLLocation {
            self.userLocation = "\(userInfo.coordinate.latitude),\(userInfo.coordinate.longitude)"
        }
    }
    
    //MARK: neigbourhoodPicker helper method
    
    func neighbourhoodPickerConfig(neighbourhoods: [String]) {
        
        mySearchTextField.filterStrings(neighbourhoods)
            mySearchTextField.theme.font = UIFont.systemFont(ofSize:14)
            mySearchTextField.highlightAttributes = [NSFontAttributeName:UIFont.boldSystemFont(ofSize:14)]
            mySearchTextField.autocorrectionType = .no
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    //MARK: getPlaces methods depending what user chooses
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        if let searchText = textField.text {
            
            if neighbourhoods.contains(searchText) {
                
                if searchText == "Current location" {
                    if let userLocation = userLocation {
                        print("User chose 'Current Location': \(userLocation)")
                    }
                } else {
                    print("User chose the neighbourhood: \(searchText)")
                }
            } else {

                //Display an alert when text is not recognized
                let alertController = UIAlertController(title: "Oops!", message:
                    "Unrecognized location. Please try again", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default,handler: nil))
                
                self.present(alertController, animated: true, completion: nil)
                
                print("The user typed the location incorrectly")
            }
        }
    }    
}


