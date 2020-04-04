//
//  MapViewController.swift
//  Co-Alarm
//
//  Created by woogie on 2020/04/04.
//  Copyright © 2020 SodaCoffee. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    let locationManager = CLLocationManager()

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        mapView.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func myLocation(lat: CLLocationDegrees, lng: CLLocationDegrees, delta: Double) {
        let coordinateLocation = CLLocationCoordinate2DMake(lat, lng)
        let spanValue = MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
        let locationRegion = MKCoordinateRegion(center: coordinateLocation, span: spanValue)
        mapView.setRegion(locationRegion, animated: true)
    }
    
    func presentStores(lat: Double, lng: Double) {
        DispatchQueue.main.async {
            for annotation in self.mapView.annotations {
                self.mapView.removeAnnotation(annotation)
            }
        }
        myLocation(lat: lat, lng: lng, delta: 0.01)
        NetworkController.sharedInstance.fetchStores(lat: lat, lng: lng, delta: 1000) { (stores) in
            if let stores = stores {
                for store in stores {
                    DispatchQueue.main.async {
                        self.setAnnotation(lat: store.lat, lng: store.lng, name: store.name, remain: store.remain ?? "null")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let storeErrorAlert = UIAlertController(title:"오류", message: "약국 데이터 수집 오류", preferredStyle: .alert)
                    storeErrorAlert.addAction(UIAlertAction(title: "확인", style: .default))
                    self.present(storeErrorAlert, animated: true, completion: nil)
                    print("parsing store error")
                }
            }
            self.locationManager.stopUpdatingLocation()
        }
    }
    
    func setAnnotation(lat: CLLocationDegrees, lng: CLLocationDegrees, name: String, remain: String) {
        let annotation = MKPointAnnotation()
        annotation.coordinate.latitude = lat
        annotation.coordinate.longitude = lng
        annotation.title = name
        switch remain {
        case "plenty":
            annotation.subtitle = "100개 이상"
        case "some":
            annotation.subtitle = "30개 이상 100개 미만"
        case "few":
            annotation.subtitle = "2개 이상 30개 미만"
        case "empty":
            annotation.subtitle = "1개 이하"
        case "break":
            annotation.subtitle = "판매중지"
        case "null":
            annotation.subtitle = "정보 없음"
        default:
            break
        }
        mapView.addAnnotation(annotation)
    }
}

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let lastLocation = locations.last
        let lat = (lastLocation?.coordinate.latitude)!, lng = (lastLocation?.coordinate.longitude)!
        presentStores(lat: lat, lng: lng)
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "anno") ?? MKAnnotationView(annotation: annotation, reuseIdentifier: "anno")
        annotationView.canShowCallout = true
        if annotation is MKUserLocation {
            return nil
        } else if annotation is MKPointAnnotation{
            switch annotation.subtitle {
            case "100개 이상":
                annotationView.image = UIImage(imageLiteralResourceName: "green")
            case "30개 이상 100개 미만":
                annotationView.image = UIImage(imageLiteralResourceName: "yellow")
            case "2개 이상 30개 미만":
                annotationView.image = UIImage(imageLiteralResourceName: "red")
            case "1개 이하":
                annotationView.image = UIImage(imageLiteralResourceName: "gray")
            case "판매중지":
                annotationView.image = UIImage(imageLiteralResourceName: "gray")
            default:
                break
            }
            return annotationView
        } else {
            return nil
        }
    }
}
