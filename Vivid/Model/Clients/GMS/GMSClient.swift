//
//  GMSClient.swift
//  Vivid
//
//  Created by Celia Gómez de Villavedón on 03/07/2017.
//  Copyright © 2017 Celia Gómez de Villavedón Pedrosa. All rights reserved.
//

import Foundation
import UIKit
import GoogleMaps
import GooglePlaces
import GooglePlacePicker
import MapKit
import CoreData
import Sync

class GMSClient: NSObject {
    
    //MARK: Properties
    var session = URLSession.shared
    
    // Core Data
    let dataStack = DataStack(modelName: "NonSmokingBarModel")
    var nonSmokingBars = [NonSmokingBar]()
    var managedObjectContext: NSManagedObjectContext!
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "NonSmokingBar")

    // MARK: Initializers
    
    override init() {
        super.init()
    }
    
    //MARK: GET
    
    func taskForGetMethod(_ method: String, parameters: [String:Any], completionHandlerForGET: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        //Set the parameters
        var parametersWithApiKey = parameters
        parametersWithApiKey[ParameterKeys.ApiKey] = Constants.ApiKey as Any
        
        //Build the URL and configure the request
        let request = NSMutableURLRequest(url: gmsURLFromParameters(parametersWithApiKey, withPathExtension: method))
        
        //Make the request
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGET(nil, NSError(domain: "taskForGetMethod", code: 1, userInfo: userInfo))
            }
            
            //GUARD: Was there an error?
            guard (error == nil) else {
                sendError("There was an error with your request: \(String(describing: error))")
                return
            }
            
            //GUARD: Did we get a succesfull 2XX response?
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }

            //GUARD: Was there any data returned?
            guard let data = data else {
                sendError("No data was retured by the request!")
                return
            }
            
            //Parse the data and use the data (happens in completion handler)
            self.convertDataWithCompletionHandler(data, completionHandlerForConvertData: completionHandlerForGET)
            
        }
        
        task.resume()
        return task
        
    }
    
    
    //MARK: Helpers
    
    //Given raw JSON, return a usable Foundtion Object
    private func convertDataWithCompletionHandler(_ data: Data, completionHandlerForConvertData: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        var parsedResult: AnyObject! = nil
        
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        } catch {
            let userInfo = [NSLocalizedDescriptionKey: "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForConvertData(parsedResult, nil)
    }
    
    //Create a url from parameters
    
    private func gmsURLFromParameters(_ parameters: [String: Any], withPathExtension: String? = nil) -> URL {
        
        var components = URLComponents()
        components.scheme = GMSClient.Constants.ApiScheme
        components.host = GMSClient.Constants.ApiHost
        components.path = GMSClient.Constants.ApiPath + (withPathExtension ?? "")
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    

    // MARK: Shared Instance
    
    class func sharedInstance() -> GMSClient {
        struct Singleton {
            static var sharedInstance = GMSClient()
        }
        return Singleton.sharedInstance
    }
}


