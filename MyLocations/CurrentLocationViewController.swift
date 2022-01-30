//
//  ViewController.swift
//  MyLocations
//
//  Created by Brang Mai on 1/23/22.
//

import UIKit
import CoreLocation

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    
    let locationManager = CLLocationManager()
    var location: CLLocation?
    var updatingLocation = false
    var lastLocationError: Error?
    
    let geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    var performingReverseGeocoding = false
    var lastGeocodingError: Error?
    
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateLabels()
        configureGetButton()
        // Do any additional setup after loading the view.
    }
    
    // MARK: - Action
    @IBAction func getLocation() {
        let authStatus = locationManager.authorizationStatus
        if authStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        if authStatus == .denied || authStatus == .restricted {
            showLocationsServicesDeniedAlert()
            return
        }
//        locationManager.delegate = self
//        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
//        locationManager.startUpdatingLocation()
        
//        startLocationManager()
        if updatingLocation {
            stopLocationManager()
        } else {
            location = nil
            lastLocationError = nil
            placemark = nil
            lastGeocodingError = nil
            startLocationManager()
        }
        updateLabels()
        configureGetButton()
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError \(error.localizedDescription)")
        
        if (error as NSError).code == CLError.locationUnknown.rawValue {
            return
        }
        lastLocationError = error
        stopLocationManager()
        updateLabels()
        configureGetButton()
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations:[CLLocation]) {
        let newLocation = locations.last!
        print("didUpdateLocations \(newLocation)")
        
        if newLocation.timestamp.timeIntervalSinceNow < -5 {
            return
        }
        
        if newLocation.horizontalAccuracy < 0 {
            return
        }

      // New section #1
      var distance = CLLocationDistance(Double.greatestFiniteMagnitude)
      if let location = location {
        distance = newLocation.distance(from: location)
      }
      // End of new section #1
      if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
          lastLocationError = nil
          location = newLocation
          
              stopLocationManager()
        if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
//            print("*** We're done!")
            stopLocationManager()
            
          // New section #2
          if distance > 0 {
            performingReverseGeocoding = false
          }
          // End of new section #2
        }
        if !performingReverseGeocoding {
//            print("*** Going to geocode")
            performingReverseGeocoding = true
            geocoder.reverseGeocodeLocation(newLocation) { placemarks, error in
                self.lastGeocodingError = error
                if error == nil, let places = placemarks, !places.isEmpty {
                    self.placemark = places.last!
                } else {
                    self.placemark = nil
                }
                self.performingReverseGeocoding = false
                //self.updateLabels()
            }
        }
            updateLabels()
      // New section #3
      } else if distance < 1 {
        let timeInterval = newLocation.timestamp.timeIntervalSince(location!.timestamp)
        if timeInterval > 10 {
          print("*** Force done!")
          stopLocationManager()
          updateLabels()
        }
        // End of new sectiton #3
      }
    }
    
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//
//        let newLocation = locations.last!
//        print("didUpdateLocations \(newLocation)")
//
//        if newLocation.timestamp.timeIntervalSinceNow < -5 {
//            return
//        }
//        if newLocation.horizontalAccuracy < 0 {
//            return
//        }
//        var distance = CLLocationDistance(Double.greatestFiniteMagnitude)
//        if let location = location {
//            distance = newLocation.distance(from: location)
//        }
//        if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
//            lastLocationError = nil
//            location = newLocation
//
//            if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
//                print("*** We're done!")
//                stopLocationManager()
//
//                if distance > 0 {
//                    performingReverseGeocoding = false
//                }
//            }
//        }
//        updateLabels()
//        configureGetButton()
//
//        if !performingReverseGeocoding {
//            print("*** Going to geocode")
//            performingReverseGeocoding = true
//            geocoder.reverseGeocodeLocation(newLocation) { placemarks, error in
//                self.lastGeocodingError = error
//                if error == nil, let places = placemarks, !places.isEmpty {
//                    self.placemark = places.last!
//                } else {
//                    self.placemark = nil
//                }
//                self.performingReverseGeocoding = false
//                self.updateLabels()
//            }
//
//            } else if distance < 1 {
//            let timeInterval = newLocation.timestamp.timeIntervalSince(location!.timestamp)
//        }
////                if let error = error {
////                    print("*** Reverse Geocoding error: \(error.localizedDescription)")
////                    return
////                }
////                if let places = placemark {
////                    print("*** Found places: \(places)")
////                }
//
//        }
//    }
    
    func updateLabels() {
        if let location = location {
            latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
            longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
            tagButton.isHidden = false
            messageLabel.text = ""
            
            if let placemark = placemark {
                addressLabel.text = string(from: placemark)
            } else if performingReverseGeocoding {
                addressLabel.text = "Searching for Address...."
            } else if lastGeocodingError != nil {
                addressLabel.text = "Error Finding Address"
            } else {
                addressLabel.text = "No Address Found"
            }
        } else {
            latitudeLabel.text = ""
            longitudeLabel.text = ""
            addressLabel.text = ""
            tagButton.isHidden = true
//            messageLabel.text = "Tab 'Get My Location' to Start"
            
            let statusMessage: String
            if let error = lastLocationError as NSError? {
                if error.domain == kCLErrorDomain && error.code == CLError.denied.rawValue {
                    statusMessage = "Location Services Disabled"
                } else {
                    statusMessage = "Error Getting Location"
                }
            } else if !CLLocationManager.locationServicesEnabled() {
                statusMessage = "Location Services Disabled"
            } else if updatingLocation {
                statusMessage = "Searching..."
            } else {
                statusMessage = "Tab 'Get My Location' to Start"
            }
            messageLabel.text = statusMessage
            configureGetButton()
        }
    }
    func string(from placemart: CLPlacemark) -> String {
        var line1 = ""
        if let tmp = placemart.subThoroughfare {
            line1 += tmp + " "
        }
        if let tmp = placemart.thoroughfare {
            line1 += tmp
        }
        
        var line2 = ""
        if let tmp = placemart.locality {
            line2 += tmp + " "
        }
        if let tmp = placemart.administrativeArea {
            line2 += tmp + " "
        }
        if let tmp = placemart.postalCode {
            line2 += tmp
        }
        return line1 + "\n" + line2
    }
    
    func startLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
            
            timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(didTimeOut), userInfo: nil, repeats: false)
        }
    }
    
    func stopLocationManager() {
        if updatingLocation {
            locationManager.startUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
            
            if let timer = timer {
                timer.invalidate()
            }
        }
    }
    
    @objc func didTimeOut() {
//        print("*** Time out")
        
        if location == nil {
            stopLocationManager()
            lastLocationError = NSError(domain: "MyLocationsErrorDomain", code: 1, userInfo: nil)
            updateLabels()
        }
    }
    
    // MARK: - Helper Methods
    func showLocationsServicesDeniedAlert() {
        let alert = UIAlertController(title: "Location Services Disabled", message: "Please enable location services for this app in Settings.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func configureGetButton() {
        if updatingLocation {
            getButton.setTitle("Stop", for: .normal)
        } else {
            getButton.setTitle("Get My Location", for: .normal)
        }
    }

}

