//
//  ViewController.swift
//  Swift Weather
//
//  Created by Jake Lin on 4/06/2014.
//  Copyright (c) 2014 rushjet. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {

    let locationManager:CLLocationManager = CLLocationManager()
    var background = UIImage(named: "background.png")

    @IBOutlet var loadingIndicator : UIActivityIndicatorView? = nil
    @IBOutlet var icon : UIImageView?
    @IBOutlet var temperature : UILabel?
    @IBOutlet var loading : UILabel?
    @IBOutlet var location : UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        self.loadingIndicator!.startAnimating()

        self.view.backgroundColor = UIColor(patternImage: background!)

        let singleFingerTap = UITapGestureRecognizer(target: self, action: "handleSingleTap:")
        self.view.addGestureRecognizer(singleFingerTap)

        if ( ios8() ) {
            if #available(iOS 8.0, *) {
                locationManager.requestAlwaysAuthorization()
            } else {
                // Fallback on earlier versions
            }
        }
        locationManager.startUpdatingLocation()
    }

    func handleSingleTap(recognizer: UITapGestureRecognizer) {
        locationManager.startUpdatingLocation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func updateWeatherInfo(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        let manager = AFHTTPRequestOperationManager()
        let url = "http://api.openweathermap.org/data/2.5/forecast?id=524901&appid=44db6a862fba0b067b1930da0d769e98"
        print(url)

        let params = ["lat":latitude, "lon":longitude, "cnt":0]
        print(params)

        manager.GET(url,
            parameters: params,
            success: { (operation: AFHTTPRequestOperation!,
                responseObject: AnyObject!) in
                print("JSON: " + responseObject.description!)

                self.updateUISuccess(responseObject as! NSDictionary!)
            },
            failure: { (operation: AFHTTPRequestOperation!,
                error: NSError!) in
                print("Error: " + error.localizedDescription)

                self.loading!.text = "Internet appears down!"
            })
    }

    func updateUISuccess(jsonResult: NSDictionary!) {
        self.loading!.text = nil
        self.loadingIndicator!.hidden = true
        self.loadingIndicator!.stopAnimating()

//        let list :NSArray = jsonResult["list"] as! NSArray
//        let dic :NSDictionary = list.objectAtIndex(0) as! NSDictionary
//        let tempResult = dic["main"]?["temp"] as! Double
//        var temperature: Double
//        if (dic["sys"]?["country"] as! String == "US") {
//            // Convert temperature to Fahrenheit if user is within the US
//            temperature = round(((tempResult - 273.15) * 1.8) + 32)
//        }
//        else {
//            // Otherwise, convert temperature to Celsius
//            temperature = round(tempResult - 273.15)
//        }
        // Is it a bug of Xcode 6? can not set the font size in IB.
        self.temperature!.font = UIFont.boldSystemFontOfSize(60)
        self.temperature!.text = "(22)°"

//        let name = dic["name"]! as! String
        self.location!.font = UIFont.boldSystemFontOfSize(25)
        self.location!.text = "(name)"

//        let condition = dic["weather"]?[0]!["id"] as! Int
//        let sunrise = dic["sys"]?["sunrise"] as! Double
//        let sunset = dic["sys"]?["sunset"] as! Double

//        var nightTime = false
//        let now = NSDate().timeIntervalSince1970
//        // println(nowAsLong)
//
//        if (now < sunrise || now > sunset) {
//            nightTime = true
//        }
        self.updateWeatherIcon(2, nightTime: true)
    }

    // Converts a Weather Condition into one of our icons.
    // Refer to: http://bugs.openweathermap.org/projects/api/wiki/Weather_Condition_Codes
    func updateWeatherIcon(condition: Int, nightTime: Bool) {
        // Thunderstorm
        if (condition < 300) {
            if nightTime {
                self.icon!.image = UIImage(named: "tstorm1_night")
            } else {
                self.icon!.image = UIImage(named: "tstorm1")
            }
        }
        // Drizzle
        else if (condition < 500) {
            self.icon!.image = UIImage(named: "light_rain")
        }
        // Rain / Freezing rain / Shower rain
        else if (condition < 600) {
            self.icon!.image = UIImage(named: "shower3")
        }
        // Snow
        else if (condition < 700) {
            self.icon!.image = UIImage(named: "snow4")
        }
        // Fog / Mist / Haze / etc.
        else if (condition < 771) {
            if nightTime {
                self.icon!.image = UIImage(named: "fog_night")
            } else {
                self.icon!.image = UIImage(named: "fog")
            }
        }
        // Tornado / Squalls
        else if (condition < 800) {
            self.icon!.image = UIImage(named: "tstorm3")
        }
        // Sky is clear
        else if (condition == 800) {
            if (nightTime){
                self.icon!.image = UIImage(named: "sunny_night") // sunny night?
            }
            else {
                self.icon!.image = UIImage(named: "sunny")
            }
        }
        // few / scattered / broken clouds
        else if (condition < 804) {
            if (nightTime){
                self.icon!.image = UIImage(named: "cloudy2_night")
            }
            else{
                self.icon!.image = UIImage(named: "cloudy2")
            }
        }
        // overcast clouds
        else if (condition == 804) {
            self.icon!.image = UIImage(named: "overcast")
        }
        // Extreme
        else if ((condition >= 900 && condition < 903) || (condition > 904 && condition < 1000)) {
            self.icon!.image = UIImage(named: "tstorm3")
        }
        // Cold
        else if (condition == 903) {
            self.icon!.image = UIImage(named: "snow5")
        }
        // Hot
        else if (condition == 904) {
            self.icon!.image = UIImage(named: "sunny")
        }
        else {
            // Weather condition not available
            self.icon!.image = UIImage(named: "dunno")
        }
    }

    /*
    func finishLaunch() {
        //ask for authorization
        let status = CLLocationManager.authorizationStatus()
        if(status == CLAuthorizationStatus.NotDetermined) {
            self.locationManager.requestAlwaysAuthorization();
        }
        else {
            locationManager.startUpdatingLocation()
        }
    }

    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if(status == CLAuthorizationStatus.NotDetermined) {
            println("Auth status unkown still!");
        }
        locationManager.startUpdatingLocation()
    }
    */

    /*
    iOS 8 Utility
    */
    func ios8() -> Bool {
        print("iOS " + UIDevice.currentDevice().systemVersion)
        if ( UIDevice.currentDevice().systemVersion == "8.0" ) {
            return true
        } else {
            return false
        }

    }

    //CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("hello")
        let location:CLLocation = locations[locations.count-1] as CLLocation

        if (location.horizontalAccuracy > 0) {
            self.locationManager.stopUpdatingLocation()
            print(location.coordinate)
            updateWeatherInfo(location.coordinate.latitude, longitude: location.coordinate.longitude)
        }
    }

    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print(error)
    }
}
